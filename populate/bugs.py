#!/usr/bin/env python3

import json
import os
import sys
from typing import Dict, List
from base_populator import BasePopulator
from bs4 import BeautifulSoup
import re

class BugPopulator(BasePopulator):
    def __init__(self, avoid_translations: bool = False):
        super().__init__()
        self.avoid_translations = avoid_translations

        if not self.nookipedia_api_key:
            raise ValueError("NOOKIPEDIA_API_KEY not found in environment variables")

    def fetch_bugs_from_nookipedia(self) -> List[Dict]:
        print("Fetching bugs from Nookipedia API...")

        response = self.session.get('https://api.nookipedia.com/nh/bugs')

        if response.status_code != 200:
            raise Exception(f"Failed to fetch bugs: {response.text}")

        bugs = response.json()
        print(f"Fetched {len(bugs)} bugs from Nookipedia")
        return bugs

    def normalize_location(self, location: str) -> str:
        location_mapping = {
            "Flying": "flying",
            "Flying near flowers": "flying",
            "Flying near blue, purple, and black flowers": "flying",
            "Flying near light sources": "flying",
            "Flying near water": "flying",
            "Flying near trash or rotten turnips": "flying",
            "On trees (any kind)": "trees",
            "On trees (hardwood and cedar)": "trees",
            "On palm trees": "trees",
            "Shaking trees": "trees",
            "Shaking trees (hardwood and cedar)": "trees",
            "Shaking non-fruit hardwood trees or cedar trees": "trees",
            "Disguised under trees": "trees",
            "On the ground": "ground",
            "Underground": "ground",
            "Pushing snowballs": "ground",
            "On flowers": "flowers",
            "On white flowers": "flowers",
            "On rivers and ponds": "water",
            "On beach rocks": "rocks",
            "On rocks and bushes": "rocks",
            "From hitting rocks": "rocks",
            "On tree stumps": "stumps",
            "On villagers": "villagers",
            "On/near spoiled turnips/candy/lollipops": "special",
            "Disguised on shoreline": "special"
        }
        return location_mapping.get(location, "ground")

    def normalize_weather(self, weather: str) -> str:
        weather_mapping = {
            "Any weather": "any",
            "Any except rain": "any",
            "Rain only": "rain"
        }
        return weather_mapping.get(weather, "any")

    def normalize_rarity(self, rarity: str) -> str:
        if not rarity or rarity.strip() == "":
            return "common"
        return rarity.lower().replace(" ", "_")

    def parse_time_range(self, time_str: str) -> Dict:
        if not time_str or time_str.lower() == "all day" or time_str == "NA":
            return None

        dash_chars = ["–", "—", "-", "—"]
        time_parts = None

        for dash in dash_chars:
            if dash in time_str:
                time_parts = time_str.split(dash)
                break

        if not time_parts or len(time_parts) != 2:
            return None

        def parse_time(time_part):
            time_part = time_part.strip()
            if "AM" in time_part or "PM" in time_part:
                time_match = re.search(r'(\d+)', time_part)
                if time_match:
                    hour = int(time_match.group(1))
                    if "PM" in time_part and hour != 12:
                        hour += 12
                    elif "AM" in time_part and hour == 12:
                        hour = 0
                    return hour
            return 0

        begin_time = parse_time(time_parts[0])
        end_time = parse_time(time_parts[1])

        return {"begin": begin_time, "end": end_time}

    def transform_availability(self, north_data: Dict, south_data: Dict) -> Dict:
        availability = {
            "north": {},
            "south": {}
        }

        if north_data and "times_by_month" in north_data:
            for month, time_str in north_data["times_by_month"].items():
                if time_str and time_str != "NA":
                    time_range = self.parse_time_range(time_str)
                    if time_range:
                        availability["north"][month] = time_range

        if south_data and "times_by_month" in south_data:
            for month, time_str in south_data["times_by_month"].items():
                if time_str and time_str != "NA":
                    time_range = self.parse_time_range(time_str)
                    if time_range:
                        availability["south"][month] = time_range

        return availability

    def transform_bug_data(self, nookipedia_bug: Dict) -> Dict:

        availability = self.transform_availability(
            nookipedia_bug.get("north", {}),
            nookipedia_bug.get("south", {})
        )

        transformed_bug = {
            "name": {
                "en": nookipedia_bug['name'],
                "jp": "",
                "es": "",
                "fr": "",
                "de": "",
                "it": "",
                "ko": "",
                "zh": "",
                "nl": "",
                "ru": ""
            },
            "location": self.normalize_location(nookipedia_bug.get('location', '')),
            "weather": self.normalize_weather(nookipedia_bug.get('weather', '')),
            "price": {
                "shop": nookipedia_bug.get('sell_nook', 0),
                "flick": nookipedia_bug.get('sell_flick', 0)
            },
            "rarity": self.normalize_rarity(nookipedia_bug.get('rarity', '')),
            "availability": availability
        }

        return transformed_bug

    def populate_single_bug(self, bug: Dict) -> Dict:
        headers = {
            'Authorization': f'Bearer {self.system_token}',
            'Content-Type': 'application/json'
        }

        response = self.session.post(
            f"{self.api_base_url}/bug",
            json=bug,
            headers=headers
        )

        if response.status_code not in [200, 201]:
            raise Exception(f"Failed to create bug: {response.text}")

        return response.json()

    def upload_bug_image(self, bug_id: str, image_type: str, image_data: str) -> Dict:
        try:
            headers = {
                'Authorization': f'Bearer {self.system_token}',
                'Content-Type': 'application/json'
            }

            url = f"{self.api_base_url}/bug/{bug_id}/img/{image_type}"

            response = self.session.post(
                url,
                json={"image_data": image_data},
                headers=headers
            )

            if response.status_code not in [200, 201]:
                raise Exception(f"Failed to upload bug image: {response.text}")

            print(f"✓ Bug image uploaded successfully: {image_type}")
            return response.json()

        except Exception as e:
            print(f"✗ Failed to upload bug image {image_type}: {str(e)}")
            raise

    def populate_bugs_to_api(self, bugs: List[Dict]) -> List[str]:
        print(f"Populating database with {len(bugs)} bugs...")

        success_count = 0
        error_count = 0
        created_bug_ids = []

        for i, bug in enumerate(bugs, 1):
            try:
                print(f"\nProcessing bug {i}/{len(bugs)}: {bug['name']}")
                transformed_bug = self.transform_bug_data(bug)

                result = self.populate_single_bug(transformed_bug)
                bug_id = result.get('bug', {}).get('_id')

                if not bug_id:
                    raise Exception("Failed to get bug ID from creation response")

                print(f"✓ Successfully created bug: {transformed_bug['name']['en']} ({bug_id})")
                created_bug_ids.append(bug_id)

                if 'image_url' in bug and bug['image_url']:
                    try:
                        image_data = self.download_image_as_base64(bug['image_url'])
                        self.upload_bug_image(bug_id, 'full', image_data)
                    except Exception as e:
                        print(f"✗ Failed to upload full image for {bug['name']}: {str(e)}")

                if 'render_url' in bug and bug['render_url']:
                    try:
                        image_data = self.download_image_as_base64(bug['render_url'])
                        self.upload_bug_image(bug_id, 'small', image_data)
                    except Exception as e:
                        print(f"✗ Failed to upload small image for {bug['name']}: {str(e)}")

                success_count += 1

            except Exception as e:
                error_count += 1
                print(f"✗ Failed to create {bug['name']} ({bug.get('number', 'unknown')}): {str(e)}")

        print(f"\n{'='*50}")
        print(f"BUGS POPULATION SUMMARY:")
        print(f"{'='*50}")
        print(f"Total processed: {len(bugs)}")
        print(f"Successfully created: {success_count}")
        print(f"Errors: {error_count}")

        return created_bug_ids

    def enhance_with_name_translations(self) -> None:
        if self.avoid_translations:
            print("Skipping name translations (--avoid-translations flag)")
            return

        print("\n" + "="*50)
        print("ENHANCING WITH NAME TRANSLATIONS")
        print("="*50)

        try:
            bugs = self.get_bugs_from_api()
            bug_names = [bug['name']['en'] for bug in bugs if bug.get('name', {}).get('en')]

            names_data = self._scrape_bug_names_data(bug_names)
            self._apply_bug_name_enhancements(bugs, names_data)

        except Exception as e:
            print(f"✗ Bug name enhancement failed: {e}")

    def _scrape_bug_names_data(self, bug_names: List[str]) -> Dict:
        print("Scraping bug name translations from Nookipedia website...")

        nookipedia_url = "https://nookipedia.com/wiki/Bug"
        response = self.session.get(nookipedia_url)

        if response.status_code != 200:
            raise Exception(f"Failed to fetch Nookipedia page: {response.status_code}")

        soup = BeautifulSoup(response.content, 'html.parser')
        table = soup.find('table', {'class': 'sortable'})

        if not table:
            raise Exception("Could not find the sortable bug table on the page")

        bug_links = {}
        rows = table.find_all('tr')[1:]

        for row in rows:
            cells = row.find_all('td')
            if len(cells) >= 1:
                bug_cell = cells[0]
                bug_link = bug_cell.find('a')
                if bug_link and bug_link.get('href'):
                    bug_name = bug_link.get_text(strip=True)
                    bug_url = f"https://nookipedia.com{bug_link.get('href')}"
                    bug_links[bug_name] = bug_url

        print(f"Found {len(bug_links)} bug page links")

        def normalize_name(name):
            return name.lower().strip().replace("'", "'")

        api_names_normalized = {normalize_name(name): name for name in bug_names}
        table_names_normalized = {normalize_name(name): name for name in bug_links.keys()}

        print(f"Debug: API has {len(api_names_normalized)} normalized names")
        print(f"Debug: Table has {len(table_names_normalized)} normalized names")

        bug_names_data = {}
        matched_count = 0

        for normalized_table_name, original_table_name in table_names_normalized.items():
            if normalized_table_name in api_names_normalized:
                matched_count += 1
                api_name = api_names_normalized[normalized_table_name]
                bug_url = bug_links[original_table_name]

                try:
                    print(f"Scraping {original_table_name} from {bug_url}")
                    bug_data = self._scrape_individual_bug_page(bug_url)
                    if bug_data:
                        bug_names_data[api_name] = bug_data
                except Exception as e:
                    print(f"⚠ Warning: Failed to scrape {original_table_name}: {str(e)}")

        print(f"Debug: Matched {matched_count} bugs out of {len(bug_links)} table entries")
        print(f"Successfully parsed name data for {len(bug_names_data)} bugs")
        return bug_names_data

    def _scrape_individual_bug_page(self, bug_url: str) -> Dict:
        response = self.session.get(bug_url)
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

    def _apply_bug_name_enhancements(self, bugs: List[Dict], names_data: Dict) -> None:
        print("Applying name enhancements...")

        matched_count = 0
        for bug in bugs:
            bug_name = bug['name']['en']
            bug_id = bug['_id']
            name_info = names_data.get(bug_name)

            if name_info:
                matched_count += 1
                try:
                    updated_names = bug['name'].copy()

                    languages = ['jp', 'es', 'fr', 'de', 'it', 'ko', 'zh', 'nl', 'ru']
                    for lang in languages:
                        if name_info['name'].get(lang):
                            updated_names[lang] = name_info['name'][lang]

                    if updated_names != bug['name']:
                        self.update_bug_names(bug_id, updated_names)
                        print(f"✓ Updated names for {bug_name}")

                except Exception as e:
                    print(f"✗ Failed to update names for {bug_name}: {str(e)}")

        print(f"Enhanced {matched_count} bugs with translated names")

    def run(self):
        try:
            print("Starting Global Bugs Population Process...")
            print(f"Configuration:")
            print(f"  - Avoid translations: {self.avoid_translations}")
            print(f"  - API Base URL: {self.api_base_url}")
            print("")

            self.get_system_token()
            print("")

            bugs_data = self.fetch_bugs_from_nookipedia()
            created_ids = self.populate_bugs_to_api(bugs_data)

            self.enhance_with_name_translations()

            print(f"\n{'='*50}")
            print("GLOBAL BUGS PROCESS COMPLETED SUCCESSFULLY!")
            print(f"{'='*50}")

        except Exception as e:
            print(f"Error: {e}")
            raise