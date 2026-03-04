// 测试导航历史 API
const http = require('http');

// 先登录获取 token
function login() {
  return new Promise((resolve, reject) => {
    const postData = JSON.stringify({
      phone: '13800138000',
      password: '123456'
    });

    const options = {
      hostname: 'localhost',
      port: 3000,
      path: '/api/v1/auth/login',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postData)
      }
    };

    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => { data += chunk; });
      res.on('end', () => {
        try {
          const response = JSON.parse(data);
          if (response.code === 200 && response.data && response.data.token) {
            console.log('✅ 登录成功');
            console.log('Token:', response.data.token.substring(0, 20) + '...');
            resolve(response.data.token);
          } else {
            reject(new Error('登录失败: ' + response.message));
          }
        } catch (err) {
          reject(err);
        }
      });
    });

    req.on('error', reject);
    req.write(postData);
    req.end();
  });
}

// 获取导航历史
function getHistory(token) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'localhost',
      port: 3000,
      path: '/api/v1/navigation/history?page=1&pageSize=20',
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${token}`
      }
    };

    console.log('\n📡 请求导航历史...');
    console.log('URL:', `http://localhost:3000${options.path}`);

    const req = http.request(options, (res) => {
      let data = '';
      console.log('HTTP状态码:', res.statusCode);
      
      res.on('data', (chunk) => { data += chunk; });
      res.on('end', () => {
        console.log('\n📥 响应内容:');
        console.log(data);
        
        try {
          const response = JSON.parse(data);
          if (response.code === 200) {
            console.log('\n✅ 获取成功');
            console.log('记录数:', response.data.list.length);
          } else {
            console.log('\n❌ 获取失败');
            console.log('错误码:', response.code);
            console.log('错误信息:', response.message);
          }
          resolve(response);
        } catch (err) {
          console.error('\n❌ 解析响应失败:', err.message);
          reject(err);
        }
      });
    });

    req.on('error', (err) => {
      console.error('\n❌ 请求失败:', err.message);
      reject(err);
    });

    req.end();
  });
}

// 执行测试
async function test() {
  try {
    const token = await login();
    await getHistory(token);
  } catch (err) {
    console.error('\n❌ 测试失败:', err.message);
  }
}

test();
