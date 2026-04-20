import { Request, Response } from 'express';

interface MediaResource {
  id: number;
  title: string;
  artist: string;
  cover: string;
  source: string;
  tag: string;
  mediaType: 'music' | 'radio';
}

const resources: MediaResource[] = [
  {
    id: 1,
    title: 'Midnight City',
    artist: 'SoundHelix Demo',
    cover: 'https://images.pexels.com/photos/1389429/pexels-photo-1389429.jpeg?auto=compress&cs=tinysrgb&w=600',
    source: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
    tag: '在线音乐',
    mediaType: 'music'
  },
  {
    id: 2,
    title: 'Ocean Pulse',
    artist: 'SoundHelix Demo',
    cover: 'https://images.pexels.com/photos/167092/pexels-photo-167092.jpeg?auto=compress&cs=tinysrgb&w=600',
    source: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
    tag: '在线音乐',
    mediaType: 'music'
  },
  {
    id: 101,
    title: 'Morning FM',
    artist: '新闻 / 交通 / 天气',
    cover: 'https://images.pexels.com/photos/164938/pexels-photo-164938.jpeg?auto=compress&cs=tinysrgb&w=600',
    source: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3',
    tag: '在线电台',
    mediaType: 'radio'
  },
  {
    id: 102,
    title: 'Travel Radio',
    artist: '轻音乐 / 伴驾',
    cover: 'https://images.pexels.com/photos/3394650/pexels-photo-3394650.jpeg?auto=compress&cs=tinysrgb&w=600',
    source: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3',
    tag: '在线电台',
    mediaType: 'radio'
  }
];

export function getMediaResources(req: Request, res: Response) {
  const { type, keyword } = req.query;

  let list = resources;

  if (type === 'music' || type === 'radio') {
    list = list.filter((item) => item.mediaType === type);
  }

  if (typeof keyword === 'string' && keyword.trim() !== '') {
    const lower = keyword.trim().toLowerCase();
    list = list.filter((item) => item.title.toLowerCase().includes(lower) || item.artist.toLowerCase().includes(lower));
  }

  res.json({
    code: 200,
    message: '获取成功',
    data: list
  });
}
