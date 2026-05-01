import { HttpService } from './HttpService';
import { ApiConfig } from '../config/ApiConfig';
import { ApiResponse } from '../models/BackendModels';

export interface MediaResourceItem {
  id: number;
  title: string;
  artist: string;
  cover: string;
  source: string;
  tag: string;
  mediaType: 'music' | 'radio';
}

export class MediaResourceService {
  private static instance: MediaResourceService;
  private httpService: HttpService;

  private constructor() {
    this.httpService = HttpService.getInstance();
  }

  static getInstance(): MediaResourceService {
    if (!MediaResourceService.instance) {
      MediaResourceService.instance = new MediaResourceService();
    }
    return MediaResourceService.instance;
  }

  async getResources(type: 'music' | 'radio', keyword?: string): Promise<ApiResponse<MediaResourceItem[]>> {
    try {
      let url = `${ApiConfig.ENDPOINTS.MEDIA_RESOURCES}?type=${type}`;
      if (keyword && keyword.trim() !== '') {
        url += `&keyword=${encodeURIComponent(keyword.trim())}`;
      }
      return await this.httpService.get<MediaResourceItem[]>(url, false);
    } catch (err) {
      return {
        code: -1,
        message: `获取媒体资源失败: ${JSON.stringify(err)}`,
        data: []
      } as ApiResponse<MediaResourceItem[]>;
    }
  }
}



