#!/usr/bin/env python3
"""
Generate English and Indonesian helper columns for assets/cleaned_restaurants.csv.

This script keeps the existing Chinese columns untouched and appends:
Name_en, Address_en, Tag_en, Name_id, Address_id, Tag_id.
"""
from __future__ import annotations

import csv
import pathlib
from typing import Dict, Iterable, List, Tuple

CITY_TRANSLATIONS: Dict[str, Tuple[str, str]] = {
    "臺北市": ("Taipei City", "Kota Taipei"),
    "台北市": ("Taipei City", "Kota Taipei"),
    "新北市": ("New Taipei City", "Kota New Taipei"),
    "基隆市": ("Keelung City", "Kota Keelung"),
    "桃園市": ("Taoyuan City", "Kota Taoyuan"),
    "新竹市": ("Hsinchu City", "Kota Hsinchu"),
    "新竹縣": ("Hsinchu County", "Kabupaten Hsinchu"),
    "宜蘭縣": ("Yilan County", "Kabupaten Yilan"),
    "苗栗縣": ("Miaoli County", "Kabupaten Miaoli"),
    "臺中市": ("Taichung City", "Kota Taichung"),
    "台中市": ("Taichung City", "Kota Taichung"),
    "彰化縣": ("Changhua County", "Kabupaten Changhua"),
    "南投縣": ("Nantou County", "Kabupaten Nantou"),
    "雲林縣": ("Yunlin County", "Kabupaten Yunlin"),
    "嘉義市": ("Chiayi City", "Kota Chiayi"),
    "嘉義縣": ("Chiayi County", "Kabupaten Chiayi"),
    "臺南市": ("Tainan City", "Kota Tainan"),
    "台南市": ("Tainan City", "Kota Tainan"),
    "高雄市": ("Kaohsiung City", "Kota Kaohsiung"),
    "屏東縣": ("Pingtung County", "Kabupaten Pingtung"),
    "花蓮縣": ("Hualien County", "Kabupaten Hualien"),
    "臺東縣": ("Taitung County", "Kabupaten Taitung"),
    "台東縣": ("Taitung County", "Kabupaten Taitung"),
    "澎湖縣": ("Penghu County", "Kabupaten Penghu"),
    "金門縣": ("Kinmen County", "Kabupaten Kinmen"),
    "連江縣": ("Lienchiang County", "Kabupaten Lienchiang"),
}

DISTRICT_TRANSLATIONS: Dict[str, Tuple[str, str]] = {
    "七股區": ("Qigu District", "Distrik Qigu"),
    "三民區": ("Sanmin District", "Distrik Sanmin"),
    "三義鄉": ("Sanyi Township", "Kecamatan Sanyi"),
    "三芝區": ("Sanzhi District", "Distrik Sanzhi"),
    "中和區": ("Zhonghe District", "Distrik Zhonghe"),
    "中壢區": ("Zhongli District", "Distrik Zhongli"),
    "中山區": ("Zhongshan District", "Distrik Zhongshan"),
    "中正區": ("Zhongzheng District", "Distrik Zhongzheng"),
    "中西區": ("West Central District", "Distrik West Central"),
    "五結鄉": ("Wujie Township", "Kecamatan Wujie"),
    "佳里區": ("Jiali District", "Distrik Jiali"),
    "信義區": ("Xinyi District", "Distrik Xinyi"),
    "信莪區": ("Xinyi District", "Distrik Xinyi"),
    "內湖區": ("Neihu District", "Distrik Neihu"),
    "八德區": ("Bade District", "Distrik Bade"),
    "前金區": ("Qianjin District", "Distrik Qianjin"),
    "北區": ("North District", "Distrik Utara"),
    "北屯區": ("Beitun District", "Distrik Beitun"),
    "北投區": ("Beitou District", "Distrik Beitou"),
    "北門區": ("Beimen District", "Distrik Beimen"),
    "南區": ("South District", "Distrik Selatan"),
    "南屯區": ("Nantun District", "Distrik Nantun"),
    "南投市": ("Nantou City", "Kota Nantou"),
    "南港區": ("Nangang District", "Distrik Nangang"),
    "南竿鄉": ("Nangan Township", "Kecamatan Nangan"),
    "口湖鄉": ("Kouhu Township", "Kecamatan Kouhu"),
    "古坑鄉": ("Gukeng Township", "Kecamatan Gukeng"),
    "台東市": ("Taitung City", "Kota Taitung"),
    "員山鄉": ("Yuanshan Township", "Kecamatan Yuanshan"),
    "員林市": ("Yuanlin City", "Kota Yuanlin"),
    "埔里鎮": ("Puli Township", "Kecamatan Puli"),
    "士林區": ("Shilin District", "Distrik Shilin"),
    "壽豐鄉": ("Shoufeng Township", "Kecamatan Shoufeng"),
    "大同區": ("Datong District", "Distrik Datong"),
    "大安區": ("Da’an District", "Distrik Daan"),
    "大里區": ("Dali District", "Distrik Dali"),
    "安平區": ("Anping District", "Distrik Anping"),
    "宜蘭市": ("Yilan City", "Kota Yilan"),
    "屏東市": ("Pingtung City", "Kota Pingtung"),
    "峨眉鄉": ("Emei Township", "Kecamatan Emei"),
    "左營區": ("Zuoying District", "Distrik Zuoying"),
    "平鎮": ("Pingzhen District", "Distrik Pingzhen"),
    "彰化市": ("Changhua City", "Kota Changhua"),
    "斗六市": ("Douliu City", "Kota Douliu"),
    "斗南鎮": ("Dounan Township", "Kecamatan Dounan"),
    "新埔鎮": ("Xinpu Township", "Kecamatan Xinpu"),
    "新店區": ("Xindian District", "Distrik Xindian"),
    "新營區": ("Xinying District", "Distrik Xinying"),
    "新興區": ("Xinxing District", "Distrik Xinxing"),
    "新莊區": ("Xinzhuang District", "Distrik Xinzhuang"),
    "東區": ("East District", "Distrik Timur"),
    "東港鎮": ("Donggang Township", "Kecamatan Donggang"),
    "東石鄉": ("Dongshi Township", "Kecamatan Dongshi"),
    "松山區": ("Songshan District", "Distrik Songshan"),
    "板橋區": ("Banqiao District", "Distrik Banqiao"),
    "林口區": ("Linkou District", "Distrik Linkou"),
    "桃園區": ("Taoyuan District", "Distrik Taoyuan"),
    "梅山鄉": ("Meishan Township", "Kecamatan Meishan"),
    "樹林區": ("Shulin District", "Distrik Shulin"),
    "永和區": ("Yonghe District", "Distrik Yonghe"),
    "永康區": ("Yongkang District", "Distrik Yongkang"),
    "池上鄉": ("Chishang Township", "Kecamatan Chishang"),
    "淡水區": ("Tamsui District", "Distrik Tamsui"),
    "清水區": ("Qingshui District", "Distrik Qingshui"),
    "湖西鄉": ("Huxi Township", "Kecamatan Huxi"),
    "潭子區": ("Tanzi District", "Distrik Tanzi"),
    "玉井區": ("Yujing District", "Distrik Yujing"),
    "瑞穗鄉": ("Ruisui Township", "Kecamatan Ruisui"),
    "番路鄉": ("Fanlu Township", "Kecamatan Fanlu"),
    "礁溪鄉": ("Jiaoxi Township", "Kecamatan Jiaoxi"),
    "竹北市": ("Zhubei City", "Kota Zhubei"),
    "竹南鎮": ("Zhunan Township", "Kecamatan Zhunan"),
    "竹崎鄉": ("Zhuqi Township", "Kecamatan Zhuqi"),
    "羅東鎮": ("Luodong Township", "Kecamatan Luodong"),
    "臺東市": ("Taitung City", "Kota Taitung"),
    "花蓮市": ("Hualien City", "Kota Hualien"),
    "苓雅區": ("Lingya District", "Distrik Lingya"),
    "苗栗市": ("Miaoli City", "Kota Miaoli"),
    "草屯鎮": ("Caotun Township", "Kecamatan Caotun"),
    "萬丹鄉": ("Wandan Township", "Kecamatan Wandan"),
    "萬巒鄉": ("Wanluan Township", "Kecamatan Wanluan"),
    "萬華區": ("Wanhua District", "Distrik Wanhua"),
    "蘆竹區": ("Luzhu District", "Distrik Luzhu"),
    "西區": ("West District", "Distrik Barat"),
    "西屯區": ("Xitun District", "Distrik Xitun"),
    "金城鎮": ("Jincheng Township", "Kecamatan Jincheng"),
    "金寧鄉": ("Jinning Township", "Kecamatan Jinning"),
    "關西鎮": ("Guanxi Township", "Kecamatan Guanxi"),
    "阿里山鄉": ("Alishan Township", "Kecamatan Alishan"),
    "頭屋鄉": ("Touwu Township", "Kecamatan Touwu"),
    "馬公市": ("Magong City", "Kota Magong"),
    "魚池鄉": ("Yuchi Township", "Kecamatan Yuchi"),
    "鳳山區": ("Fengshan District", "Distrik Fengshan"),
    "鹽埕區": ("Yancheng District", "Distrik Yancheng"),
    "鹿港鎮": ("Lukang Township", "Kecamatan Lukang"),
    "龍潭區": ("Longtan District", "Distrik Longtan"),
}

TAG_TRANSLATIONS: Dict[str, Tuple[str, str]] = {
    "清真": ("Halal", "Halal"),
    "素食": ("Vegetarian", "Vegetarian"),
}

# Token maps for name augmentation (order matters: longer tokens first)
NAME_KEYWORDS: List[Tuple[str, str, str]] = [
    ("巴基斯坦", "Pakistani", "Pakistan"),
    ("印度", "Indian", "India"),
    ("泰式", "Thai", "Thailand"),
    ("泰國", "Thai", "Thailand"),
    ("泰姬", "Taj", "Taj"),
    ("土耳其", "Turkish", "Turki"),
    ("摩洛哥", "Moroccan", "Maroko"),
    ("中東", "Middle Eastern", "Timur Tengah"),
    ("素食", "Vegetarian", "Vegetarian"),
    ("蔬食", "Vegetarian", "Vegetarian"),
    ("清真", "Halal", "Halal"),
    ("咖啡館", "Cafe", "Kafe"),
    ("咖啡廳", "Cafe", "Kafe"),
    ("咖啡", "Cafe", "Kafe"),
    ("茶樓", "Tea House", "Rumah Teh"),
    ("茶館", "Tea House", "Rumah Teh"),
    ("茶", "Tea", "Teh"),
    ("餐廳", "Restaurant", "Restoran"),
    ("飯店", "Hotel", "Hotel"),
    ("廚房", "Kitchen", "Dapur"),
    ("小館", "Bistro", "Bistro"),
    ("牛肉麵", "Beef Noodles", "Mi Daging Sapi"),
    ("牛肉", "Beef", "Daging Sapi"),
    ("麵館", "Noodle House", "Rumah Mie"),
    ("麵", "Noodles", "Mie"),
    ("火鍋", "Hot Pot", "Hot Pot"),
    ("烤肉", "Barbecue", "Barbekyu"),
    ("披薩", "Pizza", "Pizza"),
    ("咖哩", "Curry", "Kari"),
    ("炸雞", "Fried Chicken", "Ayam Goreng"),
    ("便當", "Lunch Box", "Nasi Kotak"),
    ("自助餐", "Buffet", "Prasmanan"),
]


def enrich_name(name: str, lang: str) -> str:
    base = (name or "").strip()
    if not base:
        return ""
    additions: List[str] = []
    for token, en_word, id_word in NAME_KEYWORDS:
        if token in base:
            addition = en_word if lang == "en" else id_word
            if addition and addition not in additions:
                additions.append(addition)
    if not additions:
        return base
    suffix = " ".join(additions)
    return f"{base} ({suffix})"


def translate_tag(tag: str, lang: str) -> str:
    key = (tag or "").strip()
    if not key:
        return ""
    mapping = TAG_TRANSLATIONS.get(key)
    if not mapping:
        return key
    return mapping[0] if lang == "en" else mapping[1]


def split_address(addr: str) -> Tuple[str, str, str, str, str]:
    text = (addr or "").strip()
    if not text:
        return "", "", "", "", ""

    city_en = city_id = ""
    remainder = text
    for key in sorted(CITY_TRANSLATIONS, key=len, reverse=True):
        if remainder.startswith(key):
            city_en, city_id = CITY_TRANSLATIONS[key]
            remainder = remainder[len(key) :].lstrip()
            break

    district_en = district_id = ""
    district_key = ""
    if remainder:
        for suffix in ("區", "鄉", "鎮", "市"):
            idx = remainder.find(suffix)
            if idx != -1:
                district_candidate = remainder[: idx + 1]
                district_key = district_candidate
                remainder = remainder[idx + 1 :].lstrip()
                break

    if district_key:
        district_en, district_id = DISTRICT_TRANSLATIONS.get(
            district_key, (district_key, district_key)
        )

    return city_en, city_id, district_en, district_id, remainder


def build_address(addr: str, lang: str) -> str:
    city_en, city_id, district_en, district_id, rest = split_address(addr)
    parts: List[str] = []
    if lang == "en":
        parts.extend(p for p in (city_en, district_en) if p)
    else:
        parts.extend(p for p in (city_id, district_id) if p)
    if rest:
        parts.append(rest)
    return " ".join(parts).strip()


def process_row(row: Dict[str, str]) -> Dict[str, str]:
    name = row.get("Name", "")
    address = row.get("Address", "")
    tag = (row.get("tag", "") or "").strip()

    row["Name_en"] = enrich_name(name, "en")
    row["Address_en"] = build_address(address, "en")
    row["Tag_en"] = translate_tag(tag, "en")

    row["Name_id"] = enrich_name(name, "id")
    row["Address_id"] = build_address(address, "id")
    row["Tag_id"] = translate_tag(tag, "id")
    return row


def main() -> None:
    root = pathlib.Path(__file__).resolve().parents[1]
    csv_path = root / "assets" / "cleaned_restaurants.csv"

    with csv_path.open("r", encoding="utf-8-sig", newline="") as fh:
        reader = list(csv.DictReader(fh))

    updated_rows = [process_row(dict(row)) for row in reader]

    fieldnames: List[str] = list(reader[0].keys())
    for col in ["Name_en", "Address_en", "Tag_en", "Name_id", "Address_id", "Tag_id"]:
        if col not in fieldnames:
            fieldnames.append(col)

    with csv_path.open("w", encoding="utf-8-sig", newline="") as fh:
        writer = csv.DictWriter(fh, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(updated_rows)


if __name__ == "__main__":
    main()
