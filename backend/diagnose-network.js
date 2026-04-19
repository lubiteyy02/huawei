/**
 * 网络诊断脚本
 * 检查网络配置和连接状态
 */

const os = require('os');
const http = require('http');

console.log('🔍 ========== 网络诊断 ==========\n');

// 1. 获取本机IP地址
console.log('📍 本机IP地址:');
const interfaces = os.networkInterfaces();
for (const name of Object.keys(interfaces)) {
  for (const iface of interfaces[name]) {
    // 只显示IPv4且非内部地址
    if (iface.family === 'IPv4' && !iface.internal) {
      console.log(`   ${name}: ${iface.address}`);
    }
  }
}

// 2. 检查后端服务
console.log('\n🚀 后端服务检查:');
const options = {
  hostname: 'localhost',
  port: 3000,
  path: '/health',
  method: 'GET',
  timeout: 5000
};

const req = http.request(options, (res) => {
  let data = '';
  res.on('data', (chunk) => {
    data += chunk;
  });
  res.on('end', () => {
    console.log(`   ✅ 后端服务正常运行`);
    console.log(`   响应: ${data}`);
    
    // 3. 显示前端应该使用的URL
    console.log('\n📱 前端配置建议:');
    console.log('   请将 ApiConfig.ets 中的 BASE_URL 修改为:');
    for (const name of Object.keys(interfaces)) {
      for (const iface of interfaces[name]) {
        if (iface.family === 'IPv4' && !iface.internal) {
          console.log(`   http://${iface.address}:3000/api/v1`);
        }
      }
    }
    
    console.log('\n⚠️  注意事项:');
    console.log('   1. 确保手机/模拟器与电脑在同一WiFi网络');
    console.log('   2. 关闭电脑防火墙或允许3000端口');
    console.log('   3. 修改后需要重新编译前端应用');
    
    console.log('\n✅ 诊断完成\n');
  });
});

req.on('error', (e) => {
  console.log(`   ❌ 后端服务未运行: ${e.message}`);
  console.log('   请先启动后端服务: npm run dev');
});

req.on('timeout', () => {
  console.log('   ❌ 请求超时');
  req.destroy();
});

req.end();
