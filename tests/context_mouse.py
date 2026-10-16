"""Exercise right-click press/release through a real attached Neovim UI.

Run from this repository: python3 tests/context_mouse.py (requires msgpack).
No installation, LSP server or debugger is started by this test.
"""
import os
from pathlib import Path
import select
import subprocess
import tempfile
import time

import msgpack

repo = Path.cwd()
with tempfile.TemporaryDirectory(prefix="nvim-context-ui-") as work:
    env = dict(os.environ, XDG_STATE_HOME=work + "/state", XDG_CACHE_HOME=work + "/cache", NVIM_LOG_FILE=work + "/nvim.log")
    process = subprocess.Popen(
        ["nvim", "--headless", "--embed", "-i", "NONE", "-u", "NONE", "--cmd", "set loadplugins"],
        stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=env,
    )
    unpacker = msgpack.Unpacker(raw=False)
    serial = 0

    def rpc(method, *args):
        global serial
        serial += 1
        request_id = serial
        process.stdin.write(msgpack.packb([0, request_id, method, list(args)], use_bin_type=True))
        process.stdin.flush()
        deadline = time.monotonic() + 15
        while time.monotonic() < deadline:
            for message in unpacker:
                if message[0] == 1 and message[1] == request_id:
                    if message[2]:
                        raise AssertionError(message[2])
                    return message[3]
            if select.select([process.stdout], [], [], 0.2)[0]:
                chunk = os.read(process.stdout.fileno(), 65536)
                if not chunk:
                    raise AssertionError("Neovim exited unexpectedly")
                unpacker.feed(chunk)
        raise AssertionError("RPC timeout: " + method)

    def wait_for(description, condition):
        deadline = time.monotonic() + 8
        while time.monotonic() < deadline:
            if condition():
                return
            time.sleep(0.03)
        details = lua("return {mode=vim.api.nvim_get_mode(),mouse=vim.fn.getmousepos(),ft=vim.bo.filetype,messages=vim.fn.execute('messages'),map=vim.fn.maparg('<RightMouse>', 'n', false, true).desc,imap=vim.fn.maparg('<RightMouse>', 'i', false, true).desc}" )
        raise AssertionError(description + ': ' + repr(details))

    def lua(code, *args):
        return rpc("nvim_exec_lua", code, list(args))

    try:
        rpc("nvim_ui_attach", 100, 32, {"rgb": True})
        lua("""
          local repo, lockfile = ...
          vim.opt.rtp:prepend(repo)
          vim.opt.rtp:prepend(vim.fn.stdpath('data') .. '/lazy/lazy.nvim')
          local lazy = require('lazy')
          local setup = lazy.setup
          lazy.setup = function(spec, opts)
            opts.install = { missing = false }
            opts.change_detection = { enabled = false }
            opts.lockfile = lockfile
            return setup(spec, opts)
          end
          vim.opt.rtp:prepend(vim.fn.stdpath('data') .. '/lazy/nvim-treesitter')
          require('nvim-treesitter').install = function() end
          vim.opt.rtp:prepend(vim.fn.stdpath('data') .. '/lazy/mason.nvim')
          vim.opt.rtp:prepend(vim.fn.stdpath('data') .. '/lazy/mason-lspconfig.nvim')
          local ml = require('mason-lspconfig')
          local ms = ml.setup
          ml.setup = function(opts) opts.ensure_installed = {}; return ms(opts) end
          vim.lsp.start = function() end
          vim.cmd.source(repo .. '/init.lua')
          vim.api.nvim_buf_set_lines(0, 0, -1, false, {'alpha beta', 'second line'})
          vim.bo.filetype = 'text'
          require('config.context_menu').register('mouse-test', { priority = 1, actions = function()
            return {{id='test.choose', label='Choose this symbol', run=function(ctx)
              vim.b[ctx.bufnr].clicked_column = ctx.cursor[2]
            end}}
          end })
        """, str(repo), work + "/lock.json")
        origin = rpc("nvim_get_current_buf")
        # Include insert mode: one owner of both the press and release events.
        for mode in ("n", "n", "i"):
            if mode == "i":
                rpc("nvim_input", "i")
                wait_for("Could not enter insert mode", lambda: rpc("nvim_get_mode")["mode"] == "i")
            # The click is at screen column 10 (after the line-number/sign columns).
            rpc("nvim_input_mouse", "right", "press", "", 0, 0, 10)
            wait_for("Right-click did not open menu in " + mode, lambda: lua("return vim.bo.filetype") == "TelescopePrompt")
            popup = rpc("nvim_get_current_buf")
            rpc("nvim_input_mouse", "right", "release", "", 0, 0, 10)
            time.sleep(0.1)
            assert rpc("nvim_get_current_buf") == popup, "Release replaced the menu"
            rpc("nvim_input", "\x1b")
            wait_for("Escape did not restore source", lambda: rpc("nvim_get_current_buf") == origin)
            wait_for("Source was not restored to normal mode", lambda: rpc("nvim_get_mode")["mode"] == "n")
        assert lua("return vim.o.mousemodel") == "extend"
        # Select an action from the same popup using keyboard Enter.
        rpc("nvim_input", " m")
        wait_for("Keyboard entry did not open menu", lambda: lua("return vim.bo.filetype") == "TelescopePrompt")
        rpc("nvim_input", "\r")
        wait_for("Action did not run on original buffer", lambda: lua("return vim.b[...].clicked_column ~= nil", origin))
        assert rpc("nvim_get_current_buf") == origin
        print("Context UI OK: repeated right-click, press/release, insert mode, Escape, shared keyboard entry, source callback")
    finally:
        process.terminate()
        try:
            process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait()
