import json
import os
from typing import List, Dict, Any, Optional

INPUT_FILE = "china_stations.json"
OUTPUT_FILE = "radio_stations_clean.json"

def normalize_station(station: Dict[str, Any]) -> Optional[Dict[str, Any]]:
    name = (station.get("name") or "").strip()
    url = (station.get("url") or "").strip()

    if not name:
        return None
    if str(station.get("lastcheckok")) != "1":
        return None
    if not url:
        return None

    return {
        "id": station.get("stationuuid") or name,
        "name": name,
        "url": url,
        "language": station.get("language") or "未知",
        "tags": station.get("tags") or "",
        "favicon": station.get("favicon") or "",
        "country": station.get("country") or "CN",
        "codec": station.get("codec") or "",
        "bitrate": station.get("bitrate") or 0,
        "votes": station.get("votes") or 0,
        "clickcount": station.get("clickcount") or 0
    }

def clean_and_export_radio_data(input_data: List[Any], output_file: str = OUTPUT_FILE) -> None:
    cleaned_list: List[Dict[str, Any]] = []

    for station in input_data:
        if not isinstance(station, dict):
            continue

        item = normalize_station(station)
        if item is None:
            continue

        cleaned_list.append(item)

    cleaned_list.sort(
        key=lambda x: (int(x.get("votes", 0)), int(x.get("clickcount", 0))),
        reverse=True
    )

    result = {
        "source": "radio-browser",
        "country": "CN",
        "count": len(cleaned_list),
        "stations": cleaned_list
    }

    with open(output_file, "w", encoding="utf-8") as f:
        json.dump(result, f, ensure_ascii=False, indent=2)

    print(f"✅ 清洗成功，共 {len(cleaned_list)} 个有效电台")
    print(f"📄 已输出: {os.path.abspath(output_file)}")

if __name__ == "__main__":
    try:
        with open(INPUT_FILE, "r", encoding="utf-8") as f:
            data = json.load(f)

        if not isinstance(data, list):
            raise ValueError("原始 JSON 顶层必须是数组")

        clean_and_export_radio_data(data)

    except FileNotFoundError:
        print(f"❌ 错误：找不到文件 {INPUT_FILE}")
    except json.JSONDecodeError as e:
        print(f"❌ JSON 解析错误: {e}")
    except Exception as e:
        print(f"❌ 发生未知错误: {e}")