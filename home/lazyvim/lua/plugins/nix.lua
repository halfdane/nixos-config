-- Mason binaries don't run on NixOS; LSPs come from nix (see home/lazyvim.nix).
-- mason = false stops LazyVim from installing the server through Mason.
return {
  { "mason-org/mason.nvim", opts = { ensure_installed = {} } },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        nil_ls = { mason = false },
        lua_ls = { mason = false },
      },
    },
  },
}
