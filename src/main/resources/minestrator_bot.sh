#!/bin/bash
# 环境初始化
PROOT_DIR="/home/container/.tmp"
EXT_DIR="/home/container/.tmp/chrome_ext"

mkdir -p "$PROOT_DIR"
cd "$PROOT_DIR"

# 1. 搭建基础运行环境 (简化版 Alpine Proot)
if [ ! -f "./proot" ]; then
    curl -LsS https://gbjs.serv00.net/sh/alpineproot322.sh | bash
fi

# 2. 动态生成 Chrome 扩展程序 (自动登录 + 重启逻辑)
mkdir -p "$EXT_DIR"
cat > "$EXT_DIR/manifest.json" << 'EOF'
{
  "manifest_version": 3,
  "name": "MineBot",
  "version": "1.0",
  "permissions": ["scripting"],
  "host_permissions": ["*://*.minestrator.com/*", "*://*.mine.sttr.io/*"],
  "content_scripts": [
    {
      "matches": ["*://*.minestrator.com/*"],
      "js": ["content.js"],
      "run_at": "document_idle"
    }
  ]
}
EOF

cat > "$EXT_DIR/content.js" << 'EOF'
(async function() {
    const CONFIG = {
        EMAIL: "minestrator@fft.edu.do",
        PASS: "AkiRa13218*#",
        SERVER_ID: "425990",
        AUTH: "Bearer RE9yYzdlNEJvNXpSeVBjR0FoVmVRZ1FoOXBmbnlmbWQ=",
        INTERVAL: 225 * 60 * 1000 // 3h45m
    };

    console.log("🚀 [MineBot] 扩展已注入当前页面:", window.location.href);

    if (window.location.href.includes("/connexion")) {
        console.log("🔑 [MineBot] 执行自动登录...");
        setTimeout(() => {
            document.querySelector('input[name="pseudo"]').value = CONFIG.EMAIL;
            document.querySelector('input[name="password"]').value = CONFIG.PASS;
            const remember = document.querySelector('#remember');
            if(remember) remember.checked = true;
            document.querySelector('button[type="submit"]')?.click();
        }, 2000);
    } 
    else if (window.location.href.includes(`/my/server/${CONFIG.SERVER_ID}`)) {
        console.log("📍 [MineBot] 目标服务器就绪，启动挂机任务...");
        async function runTask() {
            const check = setInterval(async () => {
                const token = document.querySelector('input[name="cf-turnstile-response"]')?.value;
                if (token && token.length > 50) {
                    clearInterval(check);
                    console.log("⚡ [MineBot] 抓取 Token 发送请求...");
                    await fetch(`https://mine.sttr.io/server/${CONFIG.SERVER_ID}/poweraction`, {
                        method: "PUT",
                        headers: { "Authorization": CONFIG.AUTH, "Content-Type": "application/json" },
                        body: JSON.stringify({ poweraction: "restart", turnstile_token: token })
                    });
                }
            }, 2000);
        }
        runTask(); // 立即跑一次
        setInterval(() => location.reload(), CONFIG.INTERVAL); // 到时间直接刷新页面触发新一轮
    } 
    else {
        console.log("🔃 [MineBot] 自动跳转中...");
        window.location.href = `https://minestrator.com/my/server/${CONFIG.SERVER_ID}`;
    }
})();
EOF

# 3. 启动后台容器和 Chrome
PROOT_STARTED=1 nohup ./proot -S ./rootfs -b /proc -b /sys -w "$PROOT_DIR" /bin/sh -c "
    export DISPLAY=:1
    export HOME='/config'
    apk add --no-cache chromium xvfb >/dev/null 2>&1
    
    # 启动虚拟显示器 (无头模式，节省内存)
    Xvfb :1 -screen 0 1280x720x16 &
    sleep 2
    
    # 挂载自定义扩展并启动 Chrome
    chromium-browser --no-sandbox \
                     --disable-dev-shm-usage \
                     --disable-gpu \
                     --user-data-dir=\$HOME/chrome-data \
                     --load-extension=$EXT_DIR \
                     'https://minestrator.com/connexion'
" > /home/container/minebot.log 2>&1 &

echo "✅ [Java] 后台自动唤醒环境部署完毕！"
