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
        """Normalize bug location to predefined categories"""
        location_mapping = {
            # Flying locations
            "Flying": "flying",
            "Flying near flowers": "flying",
            "Flying near blue, purple, and black flowers": "flying",
            "Flying near light sources": "flying",
            "Flying near water": "flying",
            "Flying near trash or rotten turnips": "flying",

            # Tree locations
            "On trees (any kind)": "trees",
            "On trees (hardwood and cedar)": "trees",
            "On palm trees": "trees",
            "Shaking trees": "trees",
            "Shaking trees (hardwood and cedar)": "trees",
            "Shaking non-fruit hardwood trees or cedar trees": "trees",
            "Disguised under trees": "trees",

            # Ground locations
            "On the ground": "ground",
            "Underground": "ground",
            "Pushing snowballs": "ground",

            # Flower locations
            "On flowers": "flowers",
            "On white flowers": "flowers",

            # Water locations
            "On rivers and ponds": "water",

            # Rock locations
            "On beach rocks": "rocks",
            "On rocks and bushes": "rocks",
            "From hitting rocks": "rocks",

            # Stump locations
            "On tree stumps": "stumps",

            # Villager locations
            "On villagers": "villagers",

            # Special locations
            "On/near spoiled turnips/candy/lollipops": "special",
            "Disguised on shoreline": "special"
        }
        return location_mapping.get(location, "ground")

    def normalize_weather(self, weather: str) -> str:
        """Normalize bug weather conditions"""
        weather_mapping = {
            "Any weather": "any",
            "Any except rain": "any",
            "Rain only": "rain"
        }
        return weather_mapping.get(weather, "any")

    def normalize_rarity(self, rarity: str) -> str:
        """Normalize rarity, defaulting to common if empty"""
        if not rarity or rarity.strip() == "":
            return "common"
        return rarity.lower().replace(" ", "_")

    def parse_time_range(self, time_str: str) -> Dict:
        """Parse time ranges like '8 AM – 5 PM' into begin/end hours"""
        if not time_str or time_str.lower() == "all day":
            return {"begin": 0, "end": 23}

        dash_chars = ["–", "—", "-", "—"]
        time_parts = None

        for dash in dash_chars:
            if dash in time_str:
                time_parts = time_str.split(dash)
                break

        if not time_parts or len(time_parts) != 2:
            return {"begin": 0, "end": 23}

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

    def transform_bug_data(self, nookipedia_bug: Dict) -> Dict:
        """Transform Nookipedia bug data to our API format"""

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
            "availability": {
                "north": nookipedia_bug.get('north', {}),
                "south": nookipedia_bug.get('south', {})
            }
        }

        return transformed_bug

    def populate_single_bug(self, bug: Dict) -> Dict:
        """Populate a single bug to the API"""
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

    def populate_bugs_to_api(self, bugs: List[Dict]) -> List[str]:
        """Populate bugs to API and return list of created bug IDs"""
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
        """Enhance bugs with translated names from web scraping"""
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
        """Scrape bug name translations from Nookipedia website"""
        print("Scraping bug name translations from Nookipedia website...")

        nookipedia_url = "https://nookipedia.com/wiki/Bug"
        response = self.session.get(nookipedia_url)

        if response.status_code != 200:
            raise Exception(f"Failed to fetch Nookipedia page: {response.status_code}")

        soup = BeautifulSoup(response.content, 'html.parser')
        table = soup.find('table', {'class': 'sortable'})

        if not table:
            raise Exception("Could not find the sortable bug table on the page")

        bug_names_data = {}
        rows = table.find_all('tr')[1:]

        for row in rows:
            try:
                cells = row.find_all('td')
                if len(cells) >= 2:
                    name_cell = cells[0]
                    bug_link = name_cell.find('a')

                    if bug_link and bug_link.get('href'):
                        bug_name = bug_link.get_text(strip=True)
                        if bug_name in bug_names:
                            bug_url = f"https://nookipedia.com{bug_link['href']}"
                            print(f"Scraping {bug_name} from {bug_url}")

                            bug_data = self._scrape_individual_bug_page(bug_url)
                            if bug_data:
                                bug_names_data[bug_name] = bug_data

            except Exception as e:
                print(f"⚠ Warning: Failed to scrape {bug_name}: {str(e)}")

        print(f"Successfully parsed name data for {len(bug_names_data)} bugs")
        return bug_names_data

    def _scrape_individual_bug_page(self, bug_url: str) -> Dict:
        """Scrape individual bug page for translations"""
        response = self.session.get(bug_url)
        if response.status_code != 200:
            return None

        soup = BeautifulSoup(response.content, 'html.parser')

        translations_section = soup.find('span', {'id': 'Names_in_other_languages'})
        if not translations_section:
            return None

        table = translations_section.find_parent().find_next('table')
        if not table:
            return None

        names = {"en": ""}

        for row in table.find_all('tr')[1:]:
            cells = row.find_all('td')
            if len(cells) >= 2:
                language_cell = cells[0]
                name_cell = cells[1]

                language_img = language_cell.find('img')
                if language_img and language_img.get('alt'):
                    language = language_img['alt'].lower()
                    name_text = name_cell.get_text(strip=True)

                    if name_text and name_text != 'N/A':
                        language_mapping = {
                            'japanese': 'jp',
                            'korean': 'ko',
                            'chinese (simplified)': 'zh',
                            'russian': 'ru',
                            'dutch': 'nl',
                            'german': 'de',
                            'spanish': 'es',
                            'french': 'fr',
                            'italian': 'it'
                        }

                        mapped_lang = language_mapping.get(language)
                        if mapped_lang:
                            names[mapped_lang] = name_text

        return {'name': names} if len(names) > 1 else None

    def _apply_bug_name_enhancements(self, bugs: List[Dict], names_data: Dict) -> None:
        """Apply name enhancements to bugs"""
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
        """Run the complete bugs workflow"""
        try:
            print("Starting Global Bugs Population Process...")
            print(f"Configuration:")
            print(f"  - Avoid translations: {self.avoid_translations}")
            print(f"  - API Base URL: {self.api_base_url}")
            print("")

            self.get_system_token()
            print("")

            # Step 1: Populate bugs from Nookipedia API
            bugs_data = self.fetch_bugs_from_nookipedia()
            created_ids = self.populate_bugs_to_api(bugs_data)

            # Step 2: Enhance with name translations (if not avoided)
            self.enhance_with_name_translations()

            print(f"\n{'='*50}")
            print("GLOBAL BUGS PROCESS COMPLETED SUCCESSFULLY!")
            print(f"{'='*50}")

        except Exception as e:
            print(f"Error: {e}")
            raise