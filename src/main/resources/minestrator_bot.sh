#!/bin/bash
PROOT_DIR="/home/container/.tmp/alpine"
EXT_DIR="/home/container/.tmp/chrome_ext"

cd "$PROOT_DIR"

# 清理旧的僵尸进程 (防止多次重启导致内存爆炸)
killall chromium-browser 2>/dev/null
killall Xvfb 2>/dev/null

# 动态生成全自动 Chrome 扩展程序
mkdir -p "$EXT_DIR"
cat > "$EXT_DIR/manifest.json" << 'EOF'
{
  "manifest_version": 3,
  "name": "MineBot Auto",
  "version": "1.0",
  "permissions": ["scripting"],
  "host_permissions": ["*://*.minestrator.com/*", "*://*.mine.sttr.io/*"],
  "content_scripts": [{
    "matches": ["*://*.minestrator.com/*"],
    "js": ["content.js"],
    "run_at": "document_idle"
  }]
}
EOF

# 生成注入的 JS 脚本
cat > "$EXT_DIR/content.js" << 'EOF'
(async function() {
    const CONFIG = {
        EMAIL: "minestrator@fft.edu.do",
        PASS: "AkiRa13218*#",
        SERVER_ID: "425990",
        AUTH: "Bearer RE9yYzdlNEJvNXpSeVBjR0FoVmVRZ1FoOXBmbnlmbWQ=",
        INTERVAL: 225 * 60 * 1000 // 3小时45分钟
    };

    // 把日志发送给 Java 插件，显示在翼龙控制台！
    const sendLog = async (msg) => {
        try { await fetch("http://127.0.0.1:18080/botlog", { method: "POST", body: msg }); } catch(e) {}
    };

    sendLog("网页已加载: " + window.location.pathname);

    // 逻辑 1: 自动登录
    if (window.location.href.includes("/connexion")) {
        sendLog("🔑 检测到未登录，正在执行自动填表与登录...");
        setTimeout(() => {
            const emailInput = document.querySelector('input[name="pseudo"]');
            const passInput = document.querySelector('input[name="password"]');
            const loginBtn = document.querySelector('button[type="submit"]') || document.querySelector('.btn-text')?.parentElement;
            
            if (emailInput && passInput) {
                emailInput.value = CONFIG.EMAIL;
                passInput.value = CONFIG.PASS;
                const remember = document.querySelector('#remember');
                if(remember) remember.checked = true;
                
                sendLog("📤 表单已填充，点击登录按钮");
                loginBtn.click();
            } else {
                sendLog("⚠️ 找不到登录输入框，可能网页结构改变");
            }
        }, 3000);
    } 
    // 逻辑 2: 监控 Token 并发送重启
    else if (window.location.href.includes(`/my/server/${CONFIG.SERVER_ID}`)) {
        sendLog("📍 目标服务器控制台就绪，开始扫描验证码...");
        
        async function runTask() {
            const check = setInterval(async () => {
                const token = document.querySelector('input[name="cf-turnstile-response"]')?.value;
                if (token && token.length > 50) {
                    clearInterval(check);
                    sendLog(`⚡ 成功抓取 Token (${token.substring(0,10)}...)，发送重启请求...`);
                    
                    try {
                        const res = await fetch(`https://mine.sttr.io/server/${CONFIG.SERVER_ID}/poweraction`, {
                            method: "PUT",
                            headers: { "Authorization": CONFIG.AUTH, "Content-Type": "application/json" },
                            body: JSON.stringify({ poweraction: "restart", turnstile_token: token })
                        });
                        const data = await res.json();
                        if (data?.api?.code === 200) {
                            sendLog("✅ [核心] 远程服务器重启指令下发成功！");
                            sendLog(`💤 任务完成，休眠 ${CONFIG.INTERVAL / 60000} 分钟...`);
                        } else {
                            sendLog(`❌ 请求失败: ${JSON.stringify(data)}`);
                        }
                    } catch(err) {
                        sendLog(`⚠️ 网络错误: ${err.message}`);
                    }
                }
            }, 2000);
        }
        
        runTask(); // 立即执行
        setInterval(() => location.reload(), CONFIG.INTERVAL); // 到时间刷新页面开启下一轮
    } 
    // 逻辑 3: 自动跳转
    else {
        sendLog("🔃 自动跳转至目标服务器页面...");
        window.location.href = `https://minestrator.com/my/server/${CONFIG.SERVER_ID}`;
    }
})();
EOF

chmod +x ./proot

# 在后台极简模式启动浏览器（无需 VNC）
PROOT_STARTED=1 nohup ./proot -S ./rootfs -b /proc -b /sys -w "$PROOT_DIR" /bin/sh -c "
    export PATH=/sbin:/bin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
    export DISPLAY=:1
    export HOME='/config'
    
    # 极简虚拟显示器（只占几兆内存）
    Xvfb :1 -screen 0 1024x768x16 -nolisten tcp &
    sleep 2
    
    # 启动 Chrome，加载自动登录扩展
    chromium-browser --no-sandbox \
                     --disable-dev-shm-usage \
                     --disable-gpu \
                     --user-data-dir=\$HOME/chrome-data \
                     --load-extension=$EXT_DIR \
                     'https://minestrator.com/connexion'
" > /dev/null 2>&1 &
