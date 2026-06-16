# azoom git hooks — Conventional Commits enforcement

Bộ `.githooks` chuẩn, **portable**, để đảm bảo commit của member tuân thủ
[Conventional Commits v1.0.0](https://www.conventionalcommits.org/en/v1.0.0/).
Tham khảo từ `kopi-v2/.githooks` và `sp-audit-pipeline/.githooks`, đã lược bỏ
phần logic riêng của từng dự án để dùng được cho mọi repo.

## Nội dung

| File | Vai trò |
|------|---------|
| `.githooks/commit-msg` | Validate format commit message (Conventional Commits, có hỗ trợ `!` breaking change). Sai → **chặn** commit. |
| `.githooks/pre-commit` | Guard portable: quét secret/token, chặn file >5 MB, chặn merge-conflict marker, cảnh báo branch-name (chỉ warning). |
| `gitignore.common` | Template `.gitignore` phổ biến (đa ngôn ngữ + OS + IDE). Quan trọng: chặn `.claude/`, `.agent/`, secrets… khỏi bị push. |
| `install-hooks.sh` | Member chạy 1 lần sau khi clone để kích hoạt hooks (`core.hooksPath=.githooks`). |
| `deploy-all.sh` | Rải `.githooks/` + gộp `gitignore.common` ra nhiều repo cùng lúc (mặc định dry-run). |

## Vì sao dùng `core.hooksPath` + commit `.githooks/` vào repo?

`.git/hooks/` là local, không share được. Bằng cách commit `.githooks/` vào
repo rồi trỏ `core.hooksPath` tới đó, hooks được **version-control và share cho
cả team** — đúng mô hình của 2 bản tham khảo.

## Áp dụng cho 1 dự án

```bash
# Trong repo đích:
cp -r /path/to/temp-setup/.githooks .
./install-hooks.sh          # hoặc: bash /path/to/temp-setup/install-hooks.sh
git add .githooks install-hooks.sh
git commit -m "ci: add conventional-commits git hooks"
```

Member khác sau khi `git pull` chỉ cần chạy `./install-hooks.sh` một lần.

## Rải ra TẤT CẢ dự án

```bash
./deploy-all.sh                 # dry-run, liệt kê repo sẽ bị tác động (~/workspaces)
./deploy-all.sh --apply         # copy .githooks + bật core.hooksPath cho từng repo
DEPTH=3 ./deploy-all.sh --apply /path/base   # tuỳ chỉnh base dir & độ sâu tìm kiếm
```

Với mỗi repo, `--apply` sẽ: (1) copy `.githooks/` + bật `core.hooksPath`,
(2) **gộp** các dòng còn thiếu từ `gitignore.common` vào `.gitignore` (idempotent,
không ghi đè), (3) nếu `.claude/` đã lỡ bị commit thì `git rm --cached` để untrack
(vẫn giữ file local). Script **không tự commit** — bạn review rồi commit
`.githooks/` + `.gitignore` trong từng repo để share cho team.

## Format được chấp nhận

```
type(scope): description       ✅ feat(auth): add token refresh
type(scope)!: description      ✅ refactor(api)!: drop v1 routes   (breaking)
```

Types: `feat | fix | docs | style | refactor | perf | test | build | ci | chore | revert`

Merge/revert/fixup/squash được tự động bỏ qua. Khi thật sự cần bỏ qua hook:
`git commit --no-verify`.
