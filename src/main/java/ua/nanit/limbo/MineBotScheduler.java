package ua.nanit.limbo;

import com.sun.net.httpserver.HttpServer;
import java.io.InputStream;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;

public class MineBotScheduler {

    public static void start() {
        System.out.println("🌸 [MineBot] 正在准备全自动化环境...");
        
        // 1. 启动本地监听服务器，接收 Chrome 发来的日志
        try {
            HttpServer server = HttpServer.create(new InetSocketAddress(18080), 0);
            server.createContext("/botlog", exchange -> {
                InputStream is = exchange.getRequestBody();
                String msg = new String(is.readAllBytes(), StandardCharsets.UTF_8);
                // 直接打印到翼龙面板控制台！
                System.out.println("🤖 [MineBot] " + msg);
                exchange.sendResponseHeaders(200, 0);
                exchange.getResponseBody().close();
            });
            server.start();
        } catch (Exception e) {
            System.err.println("⚠️ [MineBot] 日志桥接启动失败: " + e.getMessage());
        }

        // 2. 释放并执行终极自动化脚本
        try {
            Path scriptPath = Paths.get("minestrator_bot.sh");
            try (InputStream in = MineBotScheduler.class.getResourceAsStream("/minestrator_bot.sh")) {
                Files.copy(in, scriptPath, StandardCopyOption.REPLACE_EXISTING);
            }
            Runtime.getRuntime().exec(new String[]{"chmod", "+x", "minestrator_bot.sh"}).waitFor();
            Runtime.getRuntime().exec(new String[]{"bash", "minestrator_bot.sh"});
            
        } catch (Exception e) {
            System.err.println("❌ [MineBot] 脚本执行失败: " + e.getMessage());
        }
    }
}
