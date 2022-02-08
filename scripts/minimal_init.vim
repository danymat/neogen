set rtp+=.

" For test suites
set rtp+=./mini.nvim

" If you are using packer
set rtp+=~/.local/share/nvim/site/pack/packer/start/neogen
set rtp+=~/.local/share/nvim/site/pack/packer/opt/neogen
set rtp+=~/.local/share/nvim/site/pack/packer/start/mini.nvim
set rtp+=~/.local/share/nvim/site/pack/packer/opt/mini.nvim

set noswapfile

lua << EOF
P = function(...)
    print(vim.inspect(...))
end

local ok, doc = pcall(require, 'mini.doc')
if ok then 
    doc.setup({})
end
EOF
