# ChapterAI — Task Breakdown, Dependencies & Tooling Reference

**Companion document to:** `chapterai-documentation.md`
**Purpose:** Actionable task list with dependencies, plus a full catalog of tools/APIs/libraries usable at each stage (with alternatives, so you can swap based on budget, latency, or self-hosting needs).

---

## 1. Task Breakdown by Phase

Tasks are grouped into phases. Within each phase, tasks are listed in the order they should be tackled, with explicit dependencies noted so you know what has to exist before you can start a given task.

### Phase 0 — Project Setup
| # | Task | Depends On | Output |
|---|---|---|---|
| 0.1 | Initialize repo, folder structure, `.gitignore`, `README.md` | — | Empty scaffold |
| 0.2 | Set up virtual environment + `requirements.txt` | 0.1 | Reproducible env |
| 0.3 | Set up Docker + `docker-compose.yml` (API, worker, Redis, Postgres) | 0.1 | One-command local boot |
| 0.4 | Set up config management (`.env`, `config.py`, secrets handling) | 0.2 | Centralized config |
| 0.5 | Set up logging + basic error tracking (e.g., Sentry) | 0.4 | Observability from day 1 |

### Phase 1 — Ingestion
| # | Task | Depends On | Output |
|---|---|---|---|
| 1.1 | Build YouTube URL validator + metadata fetch (title, duration, thumbnail) | 0.4 | Input validation |
| 1.2 | Integrate `yt-dlp` for audio-only download | 1.1 | Raw audio file |
| 1.3 | Build file upload endpoint for direct audio/video uploads | 0.4 | Alternate input path |
| 1.4 | Audio normalization step (convert to 16kHz mono WAV via ffmpeg) | 1.2, 1.3 | STT-ready audio |
| 1.5 | Long-audio chunking logic (split with overlap for parallel STT) | 1.4 | List of audio chunks |
| 1.6 | Duration/size limits + rejection handling (e.g., reject >4 hours) | 1.1 | Guardrails |

### Phase 2 — Speech-to-Text
| # | Task | Depends On | Output |
|---|---|---|---|
| 2.1 | Integrate `faster-whisper` inference service | 1.5 | Raw transcript per chunk |
| 2.2 | Timestamp stitching across chunks (offset correction) | 2.1 | Full aligned transcript |
| 2.3 | Store transcript + word-level timestamps in DB | 2.2 | Persisted transcript |
| 2.4 | (Optional) Speaker diarization integration | 2.3 | Speaker-labeled transcript |
| 2.5 | Transcript quality check (confidence scoring, silence detection) | 2.2 | Flag low-confidence sections |

### Phase 3 — Summarization
| # | Task | Depends On | Output |
|---|---|---|---|
| 3.1 | Design chapter/takeaway JSON schema | — | Schema contract |
| 3.2 | Build map-step prompt (per-chunk summarization) | 2.3, 3.1 | Chunk-level summaries |
| 3.3 | Build reduce-step prompt (synthesize chapters across chunks) | 3.2 | Final chapter list |
| 3.4 | Build "key takeaways" extraction prompt | 3.3 | Global takeaways list |
| 3.5 | Add hallucination/grounding check (verify chapter claims against transcript) | 3.3 | Trust/accuracy layer |
| 3.6 | Cache summarization results keyed by transcript hash | 3.3 | Cost savings on reruns |

### Phase 4 — Clip Generation
| # | Task | Depends On | Output |
|---|---|---|---|
| 4.1 | LLM prompt to flag "high-value" timestamp ranges for clips | 3.3 | Candidate clip list |
| 4.2 | ffmpeg cutting logic (extract exact timestamp ranges) | 1.4, 4.1 | Raw clip files |
| 4.3 | Caption burn-in using word-level timestamps | 2.3, 4.2 | Captioned clips |
| 4.4 | Vertical crop (9:16) logic — center crop or face-tracked crop | 4.2 | Shareable short-form clips |
| 4.5 | Clip thumbnail generation | 4.2 | Preview images |

### Phase 5 — API & Job Orchestration
| # | Task | Depends On | Output |
|---|---|---|---|
| 5.1 | Build `/submit` endpoint | 0.4 | Job creation |
| 5.2 | Set up Celery + Redis task queue wiring | 0.3 | Async job execution |
| 5.3 | Chain pipeline stages as Celery task workflow (ingestion → STT → summarize → clip) | 1–4 tasks, 5.2 | Full automated pipeline |
| 5.4 | Build `/status/{job_id}` endpoint | 5.3 | Progress polling |
| 5.5 | Build `/result/{job_id}` endpoint | 3.4, 4.5 | Final structured output |
| 5.6 | Add retry/backoff logic for failed pipeline stages | 5.3 | Resilience |
| 5.7 | Add webhook option as alternative to polling | 5.4 | Push notifications |

### Phase 6 — Storage & Persistence
| # | Task | Depends On | Output |
|---|---|---|---|
| 6.1 | Set up PostgreSQL schema (jobs, transcripts, chapters, clips) | 0.3 | Data model |
| 6.2 | Set up S3-compatible bucket integration | 0.4 | Blob storage |
| 6.3 | Build cleanup/retention job (delete old temp files) | 6.2 | Storage cost control |

### Phase 7 — Frontend / Client (optional, if building UI)
| # | Task | Depends On | Output |
|---|---|---|---|
| 7.1 | Submit form (URL input or file upload) | 5.1 | User entry point |
| 7.2 | Progress/status view (polling or websocket) | 5.4 | Live feedback |
| 7.3 | Chapter list view with click-to-jump timestamps | 5.5 | Scannable output |
| 7.4 | Clip gallery with download/share buttons | 5.5 | Clip delivery |

### Phase 8 — Testing & QA
| # | Task | Depends On | Output |
|---|---|---|---|
| 8.1 | Unit tests per service (downloader, whisper, LLM, ffmpeg) | Phases 1–4 | Component confidence |
| 8.2 | Integration test: full pipeline on a short sample video | 5.3 | End-to-end validation |
| 8.3 | Load test: concurrent job submissions | 5.3 | Scaling confidence |
| 8.4 | Accuracy spot-check: compare generated chapters against manual review on 5–10 videos | 3.3 | Quality baseline |

### Phase 9 — Deployment
| # | Task | Depends On | Output |
|---|---|---|---|
| 9.1 | Containerize all services for production | 0.3 | Deployable images |
| 9.2 | Set up CI/CD pipeline (GitHub Actions) | 9.1 | Automated deploys |
| 9.3 | Deploy to cloud (ECS/Kubernetes/Fly.io/Render) | 9.1 | Live environment |
| 9.4 | Set up monitoring/alerting (uptime, job failure rate) | 9.3 | Production visibility |

---

## 2. Dependency Graph (High-Level)

```
Phase 0 (Setup)
   │
   ▼
Phase 1 (Ingestion) ──┐
   │                   │
   ▼                   │
Phase 2 (STT) ──────┐  │
   │                 │  │
   ▼                 │  │
Phase 3 (Summarize)  │  │
   │          │       │  │
   ▼          ▼       ▼  ▼
Phase 4    Phase 5 (API/Orchestration) ── Phase 6 (Storage)
(Clips)         │
   │            ▼
   └────▶ Phase 7 (Frontend, optional)
                │
                ▼
        Phase 8 (Testing) ──▶ Phase 9 (Deployment)
```

---

## 3. Tools, APIs & Libraries Catalog

For each functional need, primary recommendation plus alternatives — so you can pick based on cost, self-hosting preference, or latency needs.

### 3.1 Audio/Video Acquisition
| Need | Primary | Alternatives |
|---|---|---|
| Download YouTube audio | `yt-dlp` | `pytube` (less reliable, breaks often), `youtube-dl` (older, slower updates) |
| Generic URL/media extraction | `yt-dlp` (supports 1000+ sites) | Direct HTTP download for hosted files |
| Audio/video format conversion | `ffmpeg` | `pydub` (Python wrapper over ffmpeg, simpler API for basic tasks) |

### 3.2 Speech-to-Text
| Need | Primary | Alternatives |
|---|---|---|
| Local/self-hosted STT | `faster-whisper` (CTranslate2, fast) | `whisper.cpp` (C++, good for CPU-only/edge), OpenAI `whisper` (reference implementation, slowest) |
| Hosted/managed STT | OpenAI Whisper API | AssemblyAI, Deepgram, Google Cloud Speech-to-Text, AWS Transcribe |
| Speaker diarization | `pyannote-audio` | AssemblyAI (built-in diarization), Deepgram (built-in diarization) |
| Word-level timestamps | `faster-whisper` (native support) | AssemblyAI, Deepgram (both provide word-level timestamps out of the box) |

### 3.3 Summarization / LLM
| Need | Primary | Alternatives |
|---|---|---|
| Chapter + takeaway generation | Claude API (Sonnet-class model) | OpenAI GPT-4o/GPT-4.1, Gemini 1.5/2.0, self-hosted Llama 3.x for cost control |
| Structured JSON output | Claude API with explicit JSON schema in prompt | OpenAI function calling / structured outputs mode |
| Long-document map-reduce | Custom map-reduce with LangChain or manual chunking | LlamaIndex (built-in summarization chains) |
| Grounding/hallucination checks | Custom prompt asking LLM to cite transcript timestamps for each claim | Manual heuristic: verify keywords from summary appear near claimed timestamp in transcript |

### 3.4 Video/Clip Processing
| Need | Primary | Alternatives |
|---|---|---|
| Cutting clips by timestamp | `ffmpeg` | `moviepy` (Python-friendlier, slower for large files) |
| Caption burn-in | `ffmpeg` with `.srt`/`.ass` subtitle filter | `moviepy` TextClip overlays |
| Vertical crop / reframe | Center-crop via `ffmpeg` | Face-tracking crop: `autoflip` (Google), `opencv` + face detection heuristic |
| Auto-generate `.srt` from timestamps | Custom script (Whisper output → SRT format) | `pysrt` for SRT manipulation |

### 3.5 Backend & Orchestration
| Need | Primary | Alternatives |
|---|---|---|
| API framework | FastAPI | Flask (simpler, less async-friendly), Django REST Framework (heavier) |
| Async task queue | Celery + Redis | RQ (simpler, fewer features), Dramatiq, Temporal.io (best for complex workflows with retries/state) |
| Job scheduling (if periodic jobs needed) | Celery Beat | APScheduler, cron + script |
| Websockets for live status (optional) | FastAPI native WebSocket support | Socket.IO (`python-socketio`) |

### 3.6 Storage & Database
| Need | Primary | Alternatives |
|---|---|---|
| Relational data (jobs, chapters, metadata) | PostgreSQL | MySQL, SQLite (dev/small-scale only) |
| ORM | SQLAlchemy | Tortoise ORM (async-native), Prisma (via prisma-client-py) |
| Object storage (audio/video/clips) | AWS S3 | Cloudflare R2 (cheaper egress), Backblaze B2, DigitalOcean Spaces, MinIO (self-hosted) |
| Caching layer | Redis | Memcached |

### 3.7 Infrastructure & DevOps
| Need | Primary | Alternatives |
|---|---|---|
| Containerization | Docker + Docker Compose | Podman |
| Production orchestration | Kubernetes / AWS ECS | Fly.io, Render, Railway (simpler for smaller scale) |
| CI/CD | GitHub Actions | GitLab CI, CircleCI |
| Monitoring/error tracking | Sentry | Datadog, New Relic |
| Logging | Python `logging` + structured JSON logs → CloudWatch/Loki | ELK stack (Elasticsearch/Logstash/Kibana) |
| GPU inference hosting (for Whisper/LLM if self-hosted) | AWS EC2 GPU instances / Modal.com | RunPod, Lambda Labs, Google Cloud GPU VMs |

### 3.8 Frontend (if building a UI)
| Need | Primary | Alternatives |
|---|---|---|
| Framework | React (Next.js) | Vue/Nuxt, SvelteKit |
| Styling | Tailwind CSS | CSS Modules, Chakra UI |
| Video/clip preview player | `video.js` or native `<video>` tag | Plyr.js |
| Polling/state management | React Query (`@tanstack/react-query`) | SWR |

---

## 4. Python Dependencies (`requirements.txt` starter)

```
fastapi>=0.111
uvicorn[standard]>=0.30
celery>=5.4
redis>=5.0
sqlalchemy>=2.0
psycopg2-binary>=2.9
alembic>=1.13
pydantic>=2.7
yt-dlp>=2024.7.1
faster-whisper>=1.0
ffmpeg-python>=0.2
boto3>=1.34
anthropic>=0.30
python-dotenv>=1.0
pytest>=8.2
httpx>=0.27
```

## 5. System-Level Dependencies

| Dependency | Purpose | Install (Ubuntu/Debian) |
|---|---|---|
| `ffmpeg` | Audio/video processing, clip cutting, captioning | `apt-get install ffmpeg` |
| CUDA + cuDNN (optional) | GPU acceleration for Whisper | Follow NVIDIA CUDA install guide, match `faster-whisper` requirements |
| PostgreSQL client libs | Required for `psycopg2` | `apt-get install libpq-dev` |
| Redis server | Task queue broker | `apt-get install redis-server` (or use Docker image) |

---

## 6. Suggested Build Order (Fastest Path to a Working Demo)

If you want a minimal working end-to-end demo before fully building out every phase:

1. Phase 0 (setup) — minimal, just enough to run locally
2. Phase 1.1, 1.2, 1.4 — download + normalize one YouTube video
3. Phase 2.1, 2.2 — get a working transcript
4. Phase 3.1–3.4 — get chapters + takeaways out of the LLM (skip caching/grounding checks initially)
5. Phase 5.1, 5.5 — wire up a synchronous (non-queued) endpoint just to see it work end-to-end
6. **Then** go back and add: chunking for long content, Celery/Redis for async jobs, clip generation, storage, and the frontend

This gets you a demoable pipeline in the shortest time, with the "hardening" work (queuing, chunking, retries, storage lifecycle) layered in afterward.