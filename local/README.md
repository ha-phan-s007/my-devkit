# local/

Setup cá nhân (Claude config + terminal/shell). Tách khỏi `../git/` — vốn là
phần có thể phổ biến thành chuẩn team.

```
local/
├── install.sh              # symlink các config vào $HOME (idempotent, backup file cũ)
├── claude/
│   ├── settings.json           # ~/.claude/settings.json (model, theme, statusLine…)
│   ├── keybindings.json        # ~/.claude/keybindings.json
│   └── statusline-command.sh   # status line: cwd | branch | model | ctx% | 5h% | 7d%
├── shell/
│   ├── .zshrc  .bashrc  .bash_profile  .zprofile
│   └── .gitconfig
└── terminal/
    ├── .tmux.conf              # prefix C-a, catppuccin, tpm plugins
    ├── starship.toml           # prompt
    ├── claude-tmux.sh          # launcher chạy Claude trong tmux (alias `ss`)
    └── claude-tmux-cleanup.sh  # dọn session tmux (alias `ss-cleanup`)
```

## Cài trên máy mới

```bash
git clone git@github.com:ha-phan-s007/my-devkit.git
cd my-devkit/local
./install.sh --dry-run     # xem trước
./install.sh               # tạo symlink (file cũ được backup .bak-N)
```

## Lưu ý

- **Không chứa secret.** Chỉ là config; các file runtime/nhạy cảm của
  `~/.claude` (history, sessions, projects, credentials…) **không** được đưa vào.
- **`ss` / `ss-cleanup`**: hai alias trong `.zshrc` đã trỏ thẳng vào bản trong
  repo (`~/workspaces/my-devkit/local/terminal/...`). `ss` mở Claude trong tmux,
  `ss-cleanup` dọn session (`--list`, `--all` cũng được). Nếu clone repo ra chỗ
  khác `~/workspaces/my-devkit`, sửa lại path trong 2 alias cho khớp.
- **tmux plugins**: do tpm quản lý, không commit vào repo. Sau khi link
  `.tmux.conf`, nhấn `prefix + I` để cài.
