# Công cụ và agent skills

Kiểm kê ngày 2026-10-03. Đây là công cụ hỗ trợ phát triển, không phải dependency của ứng dụng.

## Trong repository

Các skill dưới `.agent/skills` đã bị xóa trước lần refactor này; Git vẫn ghi nhận lịch sử:

`banner-design`, `brand`, `caveman`, `design`, `design-system`, `flutter`, `graphify`, `ponytail`, `ponytail-audit`, `ponytail-review`, `slides`, `ui-styling`, `ui-ux-pro-max`.

Không có skill cài cục bộ đang hoạt động. `.agents`, `.codex`, `.aws` là thư mục trống, chỉ đọc do môi trường cung cấp; không thuộc cấu trúc ứng dụng.

## Skills toàn máy

`/home/longtran/.agents/skills`:

`cavecrew`, `caveman`, `caveman-commit`, `caveman-compress`, `caveman-discover`, `caveman-evidence-review`, `caveman-explore`, `caveman-help`, `caveman-learn`, `caveman-manage`, `caveman-optimize`, `caveman-review`, `caveman-setup`, `caveman-stats`, `find-skills`, `investigate-first`, `lean-build`, `migration`, `ponytail`, `ponytail-audit`, `ponytail-debt`, `ponytail-gain`, `ponytail-help`, `ponytail-review`, `safe-refactor`, `surgical-patch`, `verify-and-stop`.

`/home/longtran/.codex/skills`:

`.system`, `0-autoresearch-skill`, `academic-plotting`, `accelerate`, `awq`, `axolotl`, `bigcode-evaluation-harness`, `bitsandbytes`, `caveman`, `chroma`, `deepspeed`, `dspy`, `faiss`, `flash-attention`, `gguf`, `gptq`, `grpo-rl-training`, `guidance`, `hqq`, `instructor`, `llama-cpp`, `llama-factory`, `lm-evaluation-harness`, `megatron-core`, `miles`, `ml-paper-writing`, `ml-training-recipes`, `mlflow`, `nemo-evaluator`, `openrlhf`, `outlines`, `peft`, `pinecone`, `ponytail`, `presenting-conference-talks`, `pytorch-fsdp2`, `pytorch-lightning`, `qdrant`, `ray-train`, `sentence-transformers`, `sglang`, `simpo`, `slime`, `swanlab`, `systems-paper-writing`, `tensorboard`, `tensorrt-llm`, `torchforge`, `trl-fine-tuning`, `unsloth`, `verl`, `vllm`, `weights-and-biases`.

Các plugin/skill hiển thị trong phiên Codex có thể bổ sung vào danh sách toàn máy. Repo không đóng gói chúng.

## uv tools toàn máy

| Tool | Phiên bản | Lệnh |
|---|---|---|
| `anylabeling` | 0.4.36 | `anylabeling` |
| `git-filter-repo` | 2.47.0 | `git-filter-repo` |
| `graphifyy` | 0.9.58 | `graphify`, `graphify-mcp` |
| `labelme` | 7.0.4 | `labelme` |
| `markitdown` | 0.1.7 | `markitdown` |
| `modal` | 1.6.0 | `modal` |
| `specify-cli` | 1.0.6 | `specify` |

`uv tool list` không ghi được lock trong sandbox chỉ đọc. Bảng trên được đọc trực tiếp từ `uv-receipt.toml` và metadata đã cài.

Go, Flutter/Dart và Docker Compose là bộ công cụ chạy dự án. Không có `pyproject.toml`, `uv.lock` hay Python runtime trong ứng dụng. Không gỡ tool hoặc skill toàn máy vì chúng có thể phục vụ dự án khác.

## Dọn repository

Đã bỏ backend legacy không tham gia build, đồ thị Graphify, widget preview sinh tự động, thư mục build, binary backend, cấu hình IDE cục bộ, scratch và ảnh ý tưởng UI. Mã legacy vẫn có trong lịch sử Git; các file không sinh tự động được sao lưu ngoài repo trước khi xóa.

Giữ SRS, đặc tả, kế hoạch, test, migrations, lockfile và cấu hình nền tảng vì chúng phục vụ đồ án và khả năng tái lập. Đặc tả nằm ở `docs/specs`, checkpoint cũ ở `docs/archive`.

## Kiểm tra refactor

- Go test và vet cho normal/dev build đều đạt.
- Flutter dependency resolution giữ nguyên lockfile; analyzer sạch; 22 test đạt trước và sau refactor.
- PostgreSQL integration kiểm tra migration lặp lại, readiness và session/quyền Admin trong DB tạm riêng.
- Tất cả import nội bộ Flutter trỏ tới file tồn tại; chỉ migrations 1–2 được thực thi.
- Chưa build Android/iOS; workflow CI được thêm nhưng chưa chạy trên GitHub.
