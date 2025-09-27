#!/usr/bin/env python3

import json
import os
import sys
from typing import Dict, List
from base_populator import BasePopulator
from bs4 import BeautifulSoup
import re

class FishPopulator(BasePopulator):
    def __init__(self, avoid_translations: bool = False):
        super().__init__()
        self.avoid_translations = avoid_translations

        if not self.nookipedia_api_key:
            raise ValueError("NOOKIPEDIA_API_KEY not found in environment variables")

    def fetch_fishes_from_nookipedia(self) -> List[Dict]:
        print("Fetching fishes from Nookipedia API...")

        response = self.session.get('https://api.nookipedia.com/nh/fish')

        if response.status_code != 200:
            raise Exception(f"Failed to fetch fishes: {response.text}")

        fishes = response.json()
        print(f"Fetched {len(fishes)} fishes from Nookipedia")
        return fishes

    def normalize_location(self, location: str) -> str:
        location_mapping = {
            "River": "river",
            "Pond": "pond",
            "Sea": "sea",
            "Pier": "pier",
            "River (clifftop)": "river",
            "River (mouth)": "river",
            "Sea (raining)": "sea"
        }
        return location_mapping.get(location, "river")

    def normalize_rarity(self, rarity: str) -> str:
        return rarity.lower()

    def parse_time_range(self, time_str: str) -> Dict:
        if not time_str or time_str.lower() == "all day":
            return {"begin": 0, "end": 23}

        dash_chars = ["–", "—", "-", "—"]
        parts = None

        for dash in dash_chars:
            if dash in time_str:
                parts = time_str.split(dash)
                break

        if parts and len(parts) == 2:
            begin_str = parts[0].strip()
            end_str = parts[1].strip()

            begin_hour = self.parse_hour(begin_str)
            end_hour = self.parse_hour(end_str)

            if end_hour < begin_hour:
                end_hour += 24

            return {"begin": begin_hour, "end": end_hour}

        return None

    def parse_hour(self, hour_str: str) -> int:
        hour_str = hour_str.strip().upper()

        if "AM" in hour_str:
            hour = int(hour_str.replace("AM", "").strip())
            return 0 if hour == 12 else hour
        elif "PM" in hour_str:
            hour = int(hour_str.replace("PM", "").strip())
            return hour if hour == 12 else hour + 12
        else:
            return int(hour_str)

    def transform_availability(self, north_data: Dict, south_data: Dict) -> Dict:
        availability = {
            "north": {},
            "south": {}
        }

        if north_data and "times_by_month" in north_data:
            for month, time_str in north_data["times_by_month"].items():
                if time_str:
                    time_range = self.parse_time_range(time_str)
                    if time_range:
                        availability["north"][month] = time_range

        if south_data and "times_by_month" in south_data:
            for month, time_str in south_data["times_by_month"].items():
                if time_str:
                    time_range = self.parse_time_range(time_str)
                    if time_range:
                        availability["south"][month] = time_range

        return availability

    def transform_fish_data(self, nookipedia_fish: Dict) -> Dict:

        availability = self.transform_availability(
            nookipedia_fish.get("north", {}),
            nookipedia_fish.get("south", {})
        )

        transformed_fish = {
            "name": {
                "en": nookipedia_fish["name"],
                "jp": None,
                "fr": None,
                "es": None,
                "de": None,
                "it": None,
                "ko": None,
                "zh": None,
                "nl": None,
                "ru": None
            },
            "location": self.normalize_location(nookipedia_fish["location"]),
            "price": {
                "cj": nookipedia_fish.get("sell_cj", 0),
                "shop": nookipedia_fish.get("sell_nook", 0)
            },
            "availability": availability,
            "rarity": self.normalize_rarity(nookipedia_fish["rarity"])
        }

        return transformed_fish

    def populate_single_fish(self, fish: Dict) -> Dict:
        headers = {
            'Authorization': f'Bearer {self.system_token}',
            'Content-Type': 'application/json'
        }

        response = self.session.post(
            f"{self.api_base_url}/fish",
            json=fish,
            headers=headers
        )

        if response.status_code not in [200, 201]:
            raise Exception(f"Failed to populate fish {fish.get('name', {}).get('en', 'unknown')}: {response.text}")

        return response.json()

    def upload_fish_image(self, fish_id: str, image_type: str, image_data: str) -> Dict:
        try:
            headers = {
                'Authorization': f'Bearer {self.system_token}',
                'Content-Type': 'application/json'
            }

            url = f"{self.api_base_url}/fish/{fish_id}/img/{image_type}"

            response = self.session.post(
                url,
                json={"image_data": image_data},
                headers=headers
            )

            if response.status_code not in [200, 201]:
                raise Exception(f"Failed to upload fish image: {response.text}")

            print(f"✓ Fish image uploaded successfully: {image_type}")
            return response.json()

        except Exception as e:
            print(f"✗ Failed to upload fish image {image_type}: {str(e)}")
            raise

    def populate_fishes_to_api(self, fishes: List[Dict]) -> List[str]:
        print(f"Populating database with {len(fishes)} fishes...")

        success_count = 0
        error_count = 0
        created_fish_ids = []

        for i, fish in enumerate(fishes, 1):
            try:
                print(f"\nProcessing fish {i}/{len(fishes)}: {fish['name']}")
                transformed_fish = self.transform_fish_data(fish)

                result = self.populate_single_fish(transformed_fish)
                fish_id = result.get('fish', {}).get('_id')

                if not fish_id:
                    raise Exception("Failed to get fish ID from creation response")

                print(f"✓ Successfully created fish: {transformed_fish['name']['en']} ({fish_id})")
                created_fish_ids.append(fish_id)

                if 'image_url' in fish and fish['image_url']:
                    try:
                        image_data = self.download_image_as_base64(fish['image_url'])
                        self.upload_fish_image(fish_id, 'full', image_data)
                    except Exception as e:
                        print(f"✗ Failed to upload full image for {fish['name']}: {str(e)}")

                if 'render_url' in fish and fish['render_url']:
                    try:
                        image_data = self.download_image_as_base64(fish['render_url'])
                        self.upload_fish_image(fish_id, 'small', image_data)
                    except Exception as e:
                        print(f"✗ Failed to upload small image for {fish['name']}: {str(e)}")

                success_count += 1

            except Exception as e:
                print(f"✗ Error processing fish {fish.get('name', 'unknown')}: {str(e)}")
                error_count += 1
                continue

        print(f"\n=== POPULATION SUMMARY ===")
        print(f"✓ Successfully processed: {success_count}")
        print(f"✗ Errors: {error_count}")
        print(f"Total: {len(fishes)}")

        return created_fish_ids

    def enhance_with_name_translations(self) -> None:
        if self.avoid_translations:
            print("Skipping name translations (--avoid-translations flag)")
            return

        print("\n" + "="*50)
        print("ENHANCING WITH NAME TRANSLATIONS")
        print("="*50)

        try:
            fishes = self.get_fishes_from_api()
            fish_names = [fish['name']['en'] for fish in fishes if fish.get('name', {}).get('en')]

            names_data = self._scrape_fish_names_data(fish_names)
            self._apply_fish_name_enhancements(fishes, names_data)

        except Exception as e:
            print(f"✗ Fish name enhancement failed: {e}")

    def _scrape_fish_names_data(self, fish_names: List[str]) -> Dict:
        print("Scraping fish name translations from Nookipedia website...")

        nookipedia_url = "https://nookipedia.com/wiki/Fish"
        response = self.session.get(nookipedia_url)

        if response.status_code != 200:
            raise Exception(f"Failed to fetch Nookipedia page: {response.status_code}")

        soup = BeautifulSoup(response.content, 'html.parser')
        table = soup.find('table', {'class': 'sortable'})

        if not table:
            raise Exception("Could not find the fish table on the page")

        fish_links = {}
        rows = table.find_all('tr')[1:]

        for row in rows:
            cells = row.find_all('td')
            if len(cells) >= 1:
                fish_cell = cells[0]
                fish_link = fish_cell.find('a')
                if fish_link and fish_link.get('href'):
                    fish_name = fish_link.get_text(strip=True)
                    fish_url = f"https://nookipedia.com{fish_link.get('href')}"
                    fish_links[fish_name] = fish_url

        print(f"Found {len(fish_links)} fish page links")

        fish_names_data = {}
        for fish_name, fish_url in fish_links.items():
            if fish_name in fish_names:
                try:
                    print(f"Scraping translations for {fish_name}...")
                    fish_data = self._scrape_individual_fish_page(fish_url)
                    if fish_data:
                        fish_names_data[fish_name] = fish_data
                except Exception as e:
                    print(f"⚠ Warning: Failed to scrape {fish_name}: {str(e)}")

        print(f"Successfully parsed name data for {len(fish_names_data)} fishes")
        return fish_names_data

    def _scrape_individual_fish_page(self, fish_url: str) -> Dict:
        response = self.session.get(fish_url)
        if response.status_code != 200:
            return None

        soup = BeautifulSoup(response.content, 'html.parser')

        lang_section = soup.find('td', {'id': 'lang1'})
        if not lang_section:
            return None

        names = {'en': ''}

        lang_mapping = {
            'infobox-flag-ja': 'jp',
            'infobox-flag-ko': 'ko',
            'infobox-flag-it': 'it',
            'infobox-flag-de': 'de',
            'infobox-flag-zh': 'zh',
            'infobox-flag-zht': 'zh',
            'infobox-flag-fr': 'fr',
            'infobox-flag-es': 'es',
            'infobox-flag-esl': 'es',
            'infobox-flag-nl': 'nl',
            'infobox-flag-ru': 'ru'
        }

        flag_divs = lang_section.find_all('div', class_=re.compile(r'infobox-flag'))
        for flag_div in flag_divs:
            classes = flag_div.get('class', [])
            lang_code = None

            for cls in classes:
                if cls in lang_mapping:
                    lang_code = lang_mapping[cls]
                    break

            if lang_code:
                next_element = flag_div.next_sibling
                while next_element:
                    if next_element.name == 'span':
                        text = next_element.get_text(strip=True)
                        if text and text != 'N/A':
                            if not (lang_code == 'zh' and 'infobox-flag-zht' in classes and names.get('zh')):
                                names[lang_code] = text
                        break
                    next_element = next_element.next_sibling

        return {'name': names} if len(names) > 1 else None

    def _apply_fish_name_enhancements(self, fishes: List[Dict], names_data: Dict) -> None:
        print("Applying fish name enhancements...")

        matched_count = 0
        for fish in fishes:
            fish_name = fish['name']['en']
            fish_id = fish['_id']
            name_info = names_data.get(fish_name)

            if name_info:
                matched_count += 1
                try:
                    updated_names = fish['name'].copy()

                    languages = ['jp', 'es', 'fr', 'de', 'it', 'ko', 'zh', 'nl', 'ru']
                    for lang in languages:
                        if name_info['name'].get(lang):
                            updated_names[lang] = name_info['name'][lang]

                    if updated_names != fish['name']:
                        self.update_fish_names(fish_id, updated_names)
                        print(f"✓ Updated names for {fish_name}")

                except Exception as e:
                    print(f"✗ Failed to update names for {fish_name}: {str(e)}")

        print(f"Enhanced {matched_count} fishes with translated names")

    def run(self):
        print("=== FISH POPULATION STARTED ===")

        self.get_system_token()

        fish_data = self.fetch_fishes_from_nookipedia()

        created_fish_ids = self.populate_fishes_to_api(fish_data)

        self.enhance_with_name_translations()

        print(f"\n=== FISH POPULATION COMPLETED ===")
        print(f"Created {len(created_fish_ids)} fishes successfully")

def main():
    try:
        populator = FishPopulator()
        populator.run()
    except Exception as e:
        print(f"Population failed: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    main()