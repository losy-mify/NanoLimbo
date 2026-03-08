package ua.nanit.limbo;

import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;

public class MineBotScheduler {

    public static void start() {
        System.out.println("🌸 [MineBot] 正在准备自动化环境...");
        try {
            // 将 resources 里的 sh 脚本释放到服务器运行目录
            Path scriptPath = Paths.get("minestrator_bot.sh");
            try (InputStream in = MineBotScheduler.class.getResourceAsStream("/minestrator_bot.sh")) {
                if (in != null) {
                    Files.copy(in, scriptPath, StandardCopyOption.REPLACE_EXISTING);
                } else {
                    System.err.println("❌ [MineBot] 找不到脚本资源文件!");
                    return;
                }
            }
            
            // 赋予权限并执行
            Runtime.getRuntime().exec(new String[]{"chmod", "+x", "minestrator_bot.sh"}).waitFor();
            Runtime.getRuntime().exec(new String[]{"bash", "minestrator_bot.sh"});
            
            System.out.println("✅ [MineBot] 自动续期任务已在后台容器中启动 (周期: 3h45m)");
        } catch (Exception e) {
            System.err.println("❌ [MineBot] 启动失败: " + e.getMessage());
        }
    }
}
