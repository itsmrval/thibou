#!/usr/bin/env python3

import json
import os
import sys
from typing import Dict, List
from base_populator import BasePopulator

class FossilPopulator(BasePopulator):
    def __init__(self):
        super().__init__()

        if not self.nookipedia_api_key:
            raise ValueError("NOOKIPEDIA_API_KEY not found in environment variables")

    def fetch_fossils_from_nookipedia(self) -> List[Dict]:
        print("Fetching fossils from Nookipedia API...")

        response = self.session.get('https://api.nookipedia.com/nh/fossils/all')

        if response.status_code != 200:
            raise Exception(f"Failed to fetch fossils: {response.text}")

        fossils = response.json()
        print(f"Fetched {len(fossils)} fossils from Nookipedia")
        return fossils

    def normalize_part_name(self, part_name: str) -> str:
        return part_name.lower().replace(' ', '_')

    def capitalize_part_name(self, part_name: str) -> str:
        words = part_name.split()
        return ' '.join(word.capitalize() for word in words)

    def transform_fossil_data(self, nookipedia_fossil: Dict) -> Dict:
        parts = []
        total_price = 0

        for part in nookipedia_fossil.get('fossils', []):
            part_name = self.normalize_part_name(part['name'])
            part_full_name = self.capitalize_part_name(part['name'])
            part_sell = part.get('sell', 0)

            parts.append({
                'name': part_name,
                'full_name': part_full_name,
                'sell': part_sell,
                'width': part.get('width', 1.0),
                'length': part.get('length', 1.0)
            })

            total_price += part_sell

        transformed_fossil = {
            'name': {
                'en': nookipedia_fossil['name']
            },
            'room': nookipedia_fossil.get('room', 1),
            'parts': parts,
            'total_price': total_price,
            'parts_count': len(parts)
        }

        return transformed_fossil

    def populate_single_fossil(self, fossil: Dict) -> Dict:
        headers = {
            'Authorization': f'Bearer {self.system_token}',
            'Content-Type': 'application/json'
        }

        response = self.session.post(
            f"{self.api_base_url}/fossil",
            json=fossil,
            headers=headers
        )

        if response.status_code not in [200, 201]:
            raise Exception(f"Failed to create fossil: {response.text}")

        return response.json()

    def upload_fossil_part_image(self, fossil_id: str, part_name: str, image_data: str) -> Dict:
        try:
            headers = {
                'Authorization': f'Bearer {self.system_token}',
                'Content-Type': 'application/json'
            }

            url = f"{self.api_base_url}/fossil/{fossil_id}/img/{part_name}"

            response = self.session.post(
                url,
                json={"image_data": image_data},
                headers=headers
            )

            if response.status_code not in [200, 201]:
                raise Exception(f"Failed to upload fossil part image: {response.text}")

            print(f"✓ Fossil part image uploaded successfully: {part_name}")
            return response.json()

        except Exception as e:
            print(f"✗ Failed to upload fossil part image {part_name}: {str(e)}")
            raise

    def populate_fossils_to_api(self, fossils: List[Dict]) -> List[str]:
        print(f"Populating database with {len(fossils)} fossils...")

        success_count = 0
        error_count = 0
        created_fossil_ids = []

        for i, fossil in enumerate(fossils, 1):
            try:
                print(f"\nProcessing fossil {i}/{len(fossils)}: {fossil['name']}")
                transformed_fossil = self.transform_fossil_data(fossil)

                result = self.populate_single_fossil(transformed_fossil)
                fossil_id = result.get('fossil', {}).get('_id')

                if not fossil_id:
                    raise Exception("Failed to get fossil ID from creation response")

                print(f"✓ Successfully created fossil: {transformed_fossil['name']['en']} ({fossil_id})")
                created_fossil_ids.append(fossil_id)

                for part in fossil.get('fossils', []):
                    if 'image_url' in part and part['image_url']:
                        try:
                            part_name_normalized = self.normalize_part_name(part['name'])
                            image_data = self.download_image_as_base64(part['image_url'])
                            self.upload_fossil_part_image(fossil_id, part_name_normalized, image_data)
                        except Exception as e:
                            print(f"✗ Failed to upload image for {part['name']}: {str(e)}")

                success_count += 1

            except Exception as e:
                error_count += 1
                print(f"✗ Failed to create {fossil['name']}: {str(e)}")

        print(f"\n{'='*50}")
        print(f"FOSSILS POPULATION SUMMARY:")
        print(f"{'='*50}")
        print(f"Total processed: {len(fossils)}")
        print(f"Successfully created: {success_count}")
        print(f"Errors: {error_count}")

        return created_fossil_ids

    def run(self):
        try:
            print("Starting Fossils population...")
            print(f"Configuration:")
            print(f"  - API Base URL: {self.api_base_url}")
            print("")

            self.get_system_token()
            print("")

            fossils_data = self.fetch_fossils_from_nookipedia()
            created_ids = self.populate_fossils_to_api(fossils_data)

            print(f"\n{'='*50}")
            print("FOSSILS PROCESS COMPLETED SUCCESSFULLY!")
            print(f"{'='*50}")

        except Exception as e:
            print(f"Error: {e}")
            raise

if __name__ == "__main__":
    populator = FossilPopulator()
    populator.run()
