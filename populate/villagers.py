#!/usr/bin/env python3
"""
Global villagers populator that handles the complete workflow:
1. Fetch villagers from Nookipedia API
2. Enhance with house data from web scraping
3. Enhance with translated names from web scraping
"""

import requests
import json
from typing import Dict, List
import sys
from bs4 import BeautifulSoup
import re
from base_populator import BasePopulator, BaseWebPopulator

class VillagersGlobalPopulator(BasePopulator):
    def __init__(self, avoid_enhancements: bool = False, avoid_translations: bool = False, avoid_rank_enhancements: bool = False):
        super().__init__()
        self.avoid_enhancements = avoid_enhancements
        self.avoid_translations = avoid_translations
        self.avoid_rank_enhancements = avoid_rank_enhancements

        if not self.nookipedia_api_key:
            raise ValueError("NOOKIPEDIA_API_KEY not found in environment variables")

    def fetch_villagers_from_nookipedia(self) -> List[Dict]:
        """Fetch villagers from Nookipedia API"""
        print("Fetching villagers from Nookipedia API...")

        response = self.session.get('https://api.nookipedia.com/villagers')

        if response.status_code != 200:
            raise Exception(f"Failed to fetch villagers: {response.text}")

        villagers = response.json()
        print(f"Fetched {len(villagers)} villagers from Nookipedia")
        return villagers

    def transform_villager_data(self, nookipedia_villager: Dict) -> Dict:
        """Transform Nookipedia data to API format"""

        month_map = {
            'January': '01', 'February': '02', 'March': '03', 'April': '04',
            'May': '05', 'June': '06', 'July': '07', 'August': '08',
            'September': '09', 'October': '10', 'November': '11', 'December': '12'
        }

        birthday_month = month_map.get(nookipedia_villager['birthday_month'], '01')
        birthday_day = str(nookipedia_villager['birthday_day']).zfill(2)
        birthday_date = f"{birthday_day}-{birthday_month}"

        transformed_villager = {
            "name": {
                "en": nookipedia_villager['name'],
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
            "title_color": nookipedia_villager['title_color'] or "333333",
            "text_color": nookipedia_villager['text_color'] or "000000",
            "id": nookipedia_villager['id'],
            "species": nookipedia_villager['species'].lower(),
            "personality": nookipedia_villager['personality'].lower(),
            "gender": nookipedia_villager['gender'].lower(),
            "birthday_date": birthday_date,
            "sign": nookipedia_villager['sign'].lower(),
            "quote": {
                "en": nookipedia_villager['quote'],
                "jp": None,
                "es": None,
                "fr": None,
                "de": None,
                "it": None,
                "ko": None,
                "zh": None,
                "nl": None,
                "ru": None
            },
            "islander": nookipedia_villager['islander'],
            "debut": nookipedia_villager['debut'],
            "appearances": nookipedia_villager.get('appearances', [])
        }

        return transformed_villager

    def populate_villagers_to_api(self, villagers: List[Dict]) -> List[str]:
        """Populate villagers to API and return list of created villager IDs"""
        print(f"Populating database with {len(villagers)} villagers...")

        success_count = 0
        error_count = 0
        created_villager_ids = []

        for i, villager in enumerate(villagers, 1):
            try:
                print(f"\nProcessing villager {i}/{len(villagers)}: {villager['name']}")
                transformed_villager = self.transform_villager_data(villager)

                result = self.populate_single_item(transformed_villager)
                villager_id = result.get('villager', {}).get('_id')

                if not villager_id:
                    raise Exception("Failed to get villager ID from creation response")

                print(f"✓ Successfully created villager: {transformed_villager['name']['en']} ({villager_id})")
                created_villager_ids.append(villager_id)

                if 'image_url' in villager and villager['image_url']:
                    try:
                        print(f"Downloading and uploading image for {transformed_villager['name']['en']}...")
                        image_data = self.download_image_as_base64(villager['image_url'])
                        self.upload_villager_image(villager_id, 'full', image_data)
                        print(f"✓ Image successfully uploaded for {transformed_villager['name']['en']}")
                    except Exception as img_error:
                        print(f"⚠ Warning: Failed to process image for {transformed_villager['name']['en']}: {str(img_error)}")

                success_count += 1

            except Exception as e:
                error_count += 1
                print(f"✗ Failed to create {villager['name']} ({villager.get('id', 'unknown')}): {str(e)}")

        print(f"\n{'='*50}")
        print(f"VILLAGERS POPULATION SUMMARY:")
        print(f"{'='*50}")
        print(f"Total processed: {len(villagers)}")
        print(f"Successfully created: {success_count}")
        print(f"Errors: {error_count}")

        return created_villager_ids

    def enhance_with_house_data(self) -> None:
        """Enhance villagers with house data from web scraping"""
        if self.avoid_enhancements:
            print("Skipping house enhancements (--avoid-enhancements flag)")
            return

        print("\n" + "="*50)
        print("ENHANCING WITH HOUSE DATA")
        print("="*50)

        try:
            villagers = self.get_villagers_from_api()
            villager_names = [villager['name']['en'] for villager in villagers if villager.get('name', {}).get('en')]

            house_data = self._scrape_house_data(villager_names)
            self._apply_house_enhancements(villagers, house_data)

        except Exception as e:
            print(f"✗ House enhancement failed: {e}")

    def enhance_with_name_translations(self) -> None:
        """Enhance villagers with translated names from web scraping"""
        if self.avoid_translations:
            print("Skipping name translations (--avoid-translations flag)")
            return

        print("\n" + "="*50)
        print("ENHANCING WITH NAME TRANSLATIONS")
        print("="*50)

        try:
            villagers = self.get_villagers_from_api()
            villager_names = [villager['name']['en'] for villager in villagers if villager.get('name', {}).get('en')]

            names_data = self._scrape_names_data(villager_names)
            self._apply_name_enhancements(villagers, names_data)

        except Exception as e:
            print(f"✗ Name enhancement failed: {e}")

    def _scrape_house_data(self, villager_names: List[str]) -> Dict:
        """Scrape house data from Nookipedia website"""
        print("Scraping villager house data from Nookipedia website...")

        nookipedia_url = "https://nookipedia.com/wiki/Villager_house/New_Horizons"
        response = self.session.get(nookipedia_url)

        if response.status_code != 200:
            raise Exception(f"Failed to fetch Nookipedia page: {response.status_code}")

        soup = BeautifulSoup(response.content, 'html.parser')
        table = soup.find('table', {'style': re.compile(r'border-collapse:collapse.*background:#fff')})

        if not table:
            raise Exception("Could not find the villager houses table on the page")

        villager_house_data = {}
        rows = table.find_all('tr')[1:]

        for row in rows:
            cells = row.find_all('td')
            if len(cells) >= 4:
                villager_data = self._parse_house_row(cells)
                if villager_data:
                    villager_house_data[villager_data['name']] = villager_data

        print(f"Successfully parsed house data for {len(villager_house_data)} villagers")
        return villager_house_data

    def _parse_house_row(self, cells) -> Dict:
        """Parse a single house row from the table"""
        try:
            villager_cell = cells[0]
            villager_link = villager_cell.find('a', title=True)
            if not villager_link:
                return None

            villager_name = villager_link.get('title')
            villager_icon_img = villager_cell.find('img')
            villager_icon_url = villager_icon_img.get('src') if villager_icon_img else None

            interior_cell = cells[1]
            interior_img = interior_cell.find('img')
            interior_url = interior_img.get('src') if interior_img else None

            exterior_cell = cells[2]
            exterior_img = exterior_cell.find('img')
            exterior_url = exterior_img.get('src') if exterior_img else None

            parts_cell = cells[3]
            exterior_parts = self._parse_exterior_parts(parts_cell)

            return {
                'name': villager_name,
                'icon_url': self._normalize_url(villager_icon_url),
                'small_icon_image_url': self._normalize_url(villager_icon_url),
                'interior_image_url': self._normalize_url(interior_url),
                'exterior_image_url': self._normalize_url(exterior_url),
                'exterior_parts': exterior_parts
            }

        except Exception as e:
            print(f"Error parsing villager row: {e}")
            return None

    def _parse_exterior_parts(self, parts_cell) -> Dict:
        """Parse exterior parts from the parts cell"""
        parts = {}
        parts_table = parts_cell.find('table')
        if not parts_table:
            return parts

        rows = parts_table.find_all('tr')
        for row in rows:
            cells = row.find_all('td')
            if len(cells) >= 2:
                part_type_cell = cells[0]
                part_type = part_type_cell.get_text(strip=True).rstrip(':').lower()

                part_data_cell = cells[1]
                part_img = part_data_cell.find('img')
                part_img_url = part_img.get('src') if part_img else None

                part_text = part_data_cell.get_text(strip=True)
                part_name = re.sub(r'\s+', ' ', part_text).strip()

                parts[part_type] = {
                    'name': part_name,
                    'image_url': self._normalize_url(part_img_url)
                }

        return parts

    def _scrape_names_data(self, villager_names: List[str]) -> Dict:
        """Scrape name translations from Nookipedia website"""
        print("Scraping villager name translations from Nookipedia website...")

        nookipedia_url = "https://nookipedia.com/wiki/List_of_villager_names_in_other_languages"
        response = self.session.get(nookipedia_url)

        if response.status_code != 200:
            raise Exception(f"Failed to fetch Nookipedia page: {response.status_code}")

        soup = BeautifulSoup(response.content, 'html.parser')
        table = soup.find('table', {'class': 'styled color-villager'})

        if not table:
            raise Exception("Could not find the villager names table on the page")

        villager_names_data = {}
        rows = table.find_all('tr')[1:]

        for row in rows:
            cells = row.find_all('td')
            if len(cells) >= 10:
                villager_data = self._parse_names_row(cells)
                if villager_data:
                    villager_names_data[villager_data['name']['en']] = villager_data

        print(f"Successfully parsed name data for {len(villager_names_data)} villagers")
        return villager_names_data

    def _parse_names_row(self, cells) -> Dict:
        """Parse a single villager name row from the table"""
        try:
            names = {}

            english_cell = cells[0]
            english_link = english_cell.find('a')
            if english_link:
                names['en'] = english_link.get_text(strip=True)
            else:
                english_text = english_cell.get_text(strip=True)
                if english_text and english_text != 'N/A':
                    names['en'] = english_text.replace('*', '').strip()
                else:
                    return None

            if not names.get('en') or names['en'] == 'N/A':
                return None

            language_mapping = {
                1: 'jp',    # Japanese
                2: 'es',    # Spanish
                3: 'fr',    # French
                4: 'de',    # German
                5: 'it',    # Italian
                6: 'ko',    # Korean
                7: 'zh',    # Chinese
                8: 'nl',    # Dutch
                9: 'ru'     # Russian
            }

            for col_index, lang_code in language_mapping.items():
                if col_index < len(cells):
                    if lang_code == 'zh':
                        text = self._extract_chinese_simplified(cells[col_index])
                    else:
                        text = self._extract_name_from_cell(cells[col_index])

                    if text and text != 'N/A':
                        names[lang_code] = text

            return {'name': names}

        except Exception as e:
            print(f"Error parsing villager name row: {e}")
            return None

    def _extract_name_from_cell(self, cell) -> str:
        """Extract name from a table cell, handling various formats"""
        if not cell:
            return None

        text = cell.get_text(strip=True)
        if not text or text == 'N/A':
            return None

        text = re.sub(r'\s+', ' ', text).strip()
        return text

    def _extract_chinese_simplified(self, cell) -> str:
        """Extract only simplified Chinese text from cell (ignoring traditional)"""
        if not cell:
            return None

        text = cell.get_text(strip=True)
        if not text or text == 'N/A':
            return None

        simplified_match = re.search(r'Simplified:\s*([^\n\r]+?)(?:\s*Traditional:|$)', text)
        if simplified_match:
            return simplified_match.group(1).strip()

        lines = text.split('\n')
        for line in lines:
            line = line.strip()
            if line and not line.startswith('Traditional:') and not line.startswith('Simplified:'):
                if re.search(r'[\u4e00-\u9fff]', line):
                    return line

        return None

    def _normalize_url(self, url: str) -> str:
        """Normalize relative URLs to absolute URLs"""
        if not url:
            return None
        if url.startswith('//'):
            return f"https:{url}"
        elif url.startswith('/'):
            return f"https://dodo.ac{url}"
        return url

    def _apply_house_enhancements(self, villagers: List[Dict], house_data: Dict) -> None:
        """Apply house enhancements to villagers"""
        print("Applying house enhancements...")

        matched_count = 0
        for villager in villagers:
            villager_name = villager['name']['en']
            villager_id = villager['_id']
            house_info_data = house_data.get(villager_name)

            if house_info_data:
                matched_count += 1
                try:
                    print(f"\nProcessing house data for {villager_name}...")

                    house_info = {}
                    exterior_parts = house_info_data.get('exterior_parts', {})

                    if exterior_parts.get('roof', {}).get('name'):
                        house_info['roof'] = exterior_parts['roof']['name']
                    if exterior_parts.get('siding', {}).get('name'):
                        house_info['siding'] = exterior_parts['siding']['name']
                    if exterior_parts.get('door', {}).get('name'):
                        house_info['door'] = exterior_parts['door']['name']

                    if house_info:
                        self.update_villager_house_info(villager_id, house_info)

                    image_types = []
                    if house_info_data.get('small_icon_image_url'):
                        image_types.append(('small', house_info_data['small_icon_image_url']))
                    if house_info_data.get('interior_image_url'):
                        image_types.append(('interior', house_info_data['interior_image_url']))
                    if house_info_data.get('exterior_image_url'):
                        image_types.append(('exterior', house_info_data['exterior_image_url']))

                    for part_type, part_data in exterior_parts.items():
                        if part_type in ['shape', 'roof', 'siding', 'door'] and part_data.get('image_url'):
                            image_types.append((part_type, part_data['image_url']))

                    for image_type, image_url in image_types:
                        try:
                            image_data = self.download_image_as_base64(image_url)
                            self.upload_villager_image(villager_id, image_type, image_data)
                        except Exception as img_error:
                            print(f"⚠ Warning: Failed to process {image_type} image: {str(img_error)}")

                    print(f"✓ Successfully enhanced {villager_name}")

                except Exception as e:
                    print(f"✗ Failed to enhance {villager_name}: {str(e)}")

        print(f"Enhanced {matched_count} villagers with house data")

    def _apply_name_enhancements(self, villagers: List[Dict], names_data: Dict) -> None:
        """Apply name enhancements to villagers"""
        print("Applying name enhancements...")

        matched_count = 0
        for villager in villagers:
            villager_name = villager['name']['en']
            villager_id = villager['_id']
            name_info = names_data.get(villager_name)

            if name_info:
                matched_count += 1
                try:
                    updated_names = villager['name'].copy()

                    languages = ['jp', 'es', 'fr', 'de', 'it', 'ko', 'zh', 'nl', 'ru']
                    for lang in languages:
                        if name_info['name'].get(lang):
                            updated_names[lang] = name_info['name'][lang]

                    if updated_names != villager['name']:
                        self.update_villager_names(villager_id, updated_names)
                        print(f"✓ Updated names for {villager_name}")

                except Exception as e:
                    print(f"✗ Failed to update names for {villager_name}: {str(e)}")

        print(f"Enhanced {matched_count} villagers with translated names")

    def enhance_with_popularity_ranks(self) -> None:
        """Enhance villagers with popularity ranks from villagerRanks.json"""
        if self.avoid_rank_enhancements:
            print("Skipping popularity rank enhancements (--avoid-rank-enhancements flag)")
            return

        print("\n" + "="*50)
        print("ENHANCING WITH POPULARITY RANKS")
        print("="*50)

        try:
            villagers = self.get_villagers_from_api()
            villager_names = [villager['name']['en'] for villager in villagers if villager.get('name', {}).get('en')]

            ranks_data = self._load_popularity_ranks()
            self._apply_popularity_rank_enhancements(villagers, ranks_data)

        except Exception as e:
            print(f"✗ Popularity rank enhancement failed: {e}")

    def _load_popularity_ranks(self) -> Dict:
        """Load popularity ranks from villagerRanks.json"""
        print("Loading villager popularity ranks from villagerRanks.json...")

        try:
            import os
            current_dir = os.path.dirname(os.path.abspath(__file__))
            ranks_file = os.path.join(current_dir, 'villagerRanks.json')

            with open(ranks_file, 'r', encoding='utf-8') as f:
                ranks_data = json.load(f)

            print(f"Successfully loaded popularity ranks for {len(ranks_data)} villagers")
            return ranks_data

        except FileNotFoundError:
            raise Exception("villagerRanks.json not found in populate directory")
        except json.JSONDecodeError as e:
            raise Exception(f"Invalid JSON in villagerRanks.json: {e}")

    def _apply_popularity_rank_enhancements(self, villagers: List[Dict], ranks_data: Dict) -> None:
        """Apply popularity rank enhancements to villagers"""
        print("Applying popularity rank enhancements...")

        matched_count = 0
        updated_count = 0

        for villager in villagers:
            villager_name = villager['name']['en']
            villager_id = villager['_id']
            current_rank = villager.get('popularity_rank', 'unranked')
            new_rank = ranks_data.get(villager_name, 'unranked')

            if villager_name in ranks_data:
                matched_count += 1

                if current_rank != new_rank:
                    try:
                        self.update_villager_popularity_rank(villager_id, new_rank)
                        updated_count += 1
                        print(f"✓ Updated {villager_name}: {current_rank} → {new_rank}")
                    except Exception as e:
                        print(f"✗ Failed to update popularity rank for {villager_name}: {str(e)}")
                else:
                    print(f"- {villager_name}: already has rank {current_rank}")

        print(f"Matched {matched_count} villagers with popularity ranks")
        print(f"Updated {updated_count} villagers with new popularity ranks")

    def run(self):
        """Run the complete villagers workflow"""
        try:
            print("Starting Global Villagers Population Process...")
            print(f"Configuration:")
            print(f"  - Avoid enhancements: {self.avoid_enhancements}")
            print(f"  - Avoid translations: {self.avoid_translations}")
            print(f"  - Avoid rank enhancements: {self.avoid_rank_enhancements}")
            print(f"  - API Base URL: {self.api_base_url}")
            print("")

            self.get_system_token()
            print("")

            villagers_data = self.fetch_villagers_from_nookipedia()
            self.populate_villagers_to_api(villagers_data)

            self.enhance_with_house_data()

            self.enhance_with_name_translations()

            self.enhance_with_popularity_ranks()

            print(f"\n{'='*50}")
            print("GLOBAL VILLAGERS PROCESS COMPLETED SUCCESSFULLY!")
            print(f"{'='*50}")

        except Exception as e:
            print(f"Error: {e}")
            raise