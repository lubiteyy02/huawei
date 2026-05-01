import os from 'os';

/**
 * 获取本机局域网IPv4地址
 */
export function getLocalIPv4(): string {
  const interfaces = os.networkInterfaces();

  for (const name of Object.keys(interfaces)) {
    const addresses = interfaces[name] || [];
    for (const address of addresses) {
      if (address.family === 'IPv4' && !address.internal) {
        return address.address;
      }
    }
  }

  return '127.0.0.1';
}
