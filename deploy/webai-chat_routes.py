import json
from fastapi import APIRouter, Depends, File, HTTPException, Request, UploadFile
from fastapi.responses import StreamingResponse
from pydantic import BaseModel

from webai_server import auth
from webai_server.upload_limits import read_upload_limited
from webai_provider_chatgpt import cred_store as db
from webai_provider_chatgpt.chatgpt_state import get_state, require_client

router = APIRouter(prefix="/api/chat", tags=["Chat"])


class ChatRequest(BaseModel):
    message: str
    conversation_id: str | None = None
    chat_id: str | None = None
    parent_message_id: str | None = None
    model: str | None = "auto"
    user_message: str | None = None


class StopRequest(BaseModel):
    conversation_id: str | None = None


def _conv_id(req: ChatRequest) -> str | None:
    return req.conversation_id or req.chat_id


def _model(req: ChatRequest) -> str:
    m = (req.model or "").strip()
    return m if m and m != "default" else "auto"


def _user_text(req: ChatRequest) -> str:
    u = (req.user_message or req.message).strip()
    return u or req.message


def _tracking_meta(request: Request) -> str:
    parts = []
    src = request.headers.get("x-portfolio-source")
    if src:
        parts.append(f"source:{src[:32]}")
    vid = request.headers.get("x-portfolio-visitor")
    if vid:
        parts.append(f"visitor:{vid[:64]}")
    ip = request.headers.get("cf-connecting-ip") or request.headers.get("x-real-ip")
    if ip:
        parts.append(f"ip:{ip[:45]}")
    return "|".join(parts)


@router.post("", operation_id="chatgpt_chat")
async def chat(req: ChatRequest, request: Request, user=Depends(auth.get_current_user)):
    state = await get_state(user["id"])
    client = require_client(state, user["id"])
    conv_holder: list[str] = []
    chunks: list[str] = []
    try:
        async for delta in client.chat(
            req.message,
            conversation_id=_conv_id(req),
            parent_message_id=req.parent_message_id,
            model=_model(req),
            conv_id_holder=conv_holder,
        ):
            chunks.append(delta)
    except Exception as e:
        raise HTTPException(500, str(e)) from e
    text = "".join(chunks)
    cid = conv_holder[0] if conv_holder else _conv_id(req)
    if cid:
        meta = _tracking_meta(request)
        await db.save_message(user["id"], cid, "user", _user_text(req), meta)
        await db.save_message(user["id"], cid, "assistant", text)
    return {"text": text, "conversation_id": cid, "chat_id": cid}


@router.post("/stream", operation_id="chatgpt_chat_stream")
async def chat_stream(req: ChatRequest, request: Request, user=Depends(auth.get_current_user)):
    state = await get_state(user["id"])
    client = require_client(state, user["id"])

    async def gen():
        conv_holder: list[str] = []
        full: list[str] = []
        try:
            async for delta in client.chat(
                req.message,
                conversation_id=_conv_id(req),
                parent_message_id=req.parent_message_id,
                model=_model(req),
                conv_id_holder=conv_holder,
            ):
                full.append(delta)
                yield f"data: {json.dumps({'delta': delta})}\n\n"
            cid = conv_holder[0] if conv_holder else _conv_id(req)
            if cid:
                meta = _tracking_meta(request)
                await db.save_message(user["id"], cid, "user", _user_text(req), meta)
                await db.save_message(user["id"], cid, "assistant", "".join(full))
            yield f"data: {json.dumps({'done': True, 'chat_id': cid, 'conversation_id': cid})}\n\n"
        except Exception as e:
            yield f"data: {json.dumps({'error': str(e)})}\n\n"

    return StreamingResponse(gen(), media_type="text/event-stream")


@router.post("/upload", operation_id="chatgpt_chat_upload")
async def chat_upload(
    file: UploadFile = File(...),
    user=Depends(auth.get_current_user),
):
    state = await get_state(user["id"])
    client = require_client(state, user["id"])
    data = await read_upload_limited(file)
    if not data:
        raise HTTPException(400, "Empty file")
    try:
        att = await client.upload_file(
            data,
            file.filename or "upload",
            mime_type=file.content_type,
        )
    except Exception as e:
        raise HTTPException(500, str(e)) from e
    return {
        "file_id": att.file_id,
        "name": att.name,
        "size": att.size,
        "mime_type": att.mime_type,
    }


@router.post("/stop", operation_id="chatgpt_chat_stop")
async def chat_stop(
    req: StopRequest | None = None,
    user=Depends(auth.get_current_user),
):
    state = await get_state(user["id"])
    client = require_client(state, user["id"])
    conv_id = req.conversation_id if req else None
    try:
        return await client.stop_generation(conversation_id=conv_id)
    except Exception as e:
        raise HTTPException(500, str(e)) from e
