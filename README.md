# my-devkit

Bộ công cụ & cấu hình dev cá nhân — khởi đầu cho riêng tôi, phần `git/` được
thiết kế để có thể "tốt nghiệp" thành **chuẩn chung cho team**.

```
my-devkit/
├── git/        # Chuẩn git: hooks (Conventional Commits), gitignore, scripts deploy
│   └── README.md   ← hướng dẫn chi tiết
└── local/      # Setup cá nhân (dotfiles, config .claude/agent…)
```

## git/ — chuẩn commit & gitignore cho mọi repo

Đảm bảo commit tuân thủ [Conventional Commits v1.0.0](https://www.conventionalcommits.org/en/v1.0.0/)
qua `commit-msg` hook, kèm `pre-commit` guard portable và template `.gitignore`
(chặn `.claude/`, secrets, file lớn…). Xem [`git/README.md`](git/README.md).

Áp dụng nhanh cho 1 repo:
```bash
cp -r my-devkit/git/.githooks .
bash my-devkit/git/install-hooks.sh
```

Rải ra nhiều repo:
```bash
bash my-devkit/git/deploy-all.sh            # dry-run
bash my-devkit/git/deploy-all.sh --apply    # áp dụng
```
