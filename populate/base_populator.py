import os
import requests
from typing import Dict, List, Any
from abc import ABC, abstractmethod
import base64
from PIL import Image
import io

class BasePopulator(ABC):

    def __init__(self):
        self.nookipedia_api_key = os.getenv('NOOKIPEDIA_API_KEY')
        self.system_key = os.getenv('SYSTEM_KEY')
        self.api_base_url = os.getenv('API_BASE_URL', 'https://api.thibou.valentinp.fr')

        if not self.system_key:
            raise ValueError("SYSTEM_KEY not found in environment variables")

        self.session = requests.Session()
        self.session.headers.update({
            'Content-Type': 'application/json'
        })

        if self.nookipedia_api_key:
            self.session.headers.update({
                'X-API-KEY': self.nookipedia_api_key
            })

        self.system_token = None

    def get_system_token(self) -> str:
        response = self.session.post(
            f"{self.api_base_url}/auth/system",
            json={"key": self.system_key}
        )

        if response.status_code != 200:
            raise Exception(f"Failed to get system token: {response.text}")

        data = response.json()
        self.system_token = data['token']
        print(f"System token obtained: {self.system_token[:50]}...")
        return self.system_token

    def get_villagers_from_api(self) -> List[Dict]:
        headers = {
            'Authorization': f'Bearer {self.system_token}',
            'Content-Type': 'application/json'
        }

        response = self.session.get(
            f"{self.api_base_url}/villager",
            headers=headers
        )

        if response.status_code != 200:
            raise Exception(f"Failed to fetch villagers from API: {response.text}")

        response_data = response.json()
        villagers = response_data.get('villagers', [])
        print(f"Fetched {len(villagers)} villagers from API")
        return villagers

    def populate_single_item(self, item: Dict) -> Dict:
        headers = {
            'Authorization': f'Bearer {self.system_token}',
            'Content-Type': 'application/json'
        }

        response = self.session.post(
            f"{self.api_base_url}/villager",
            json=item,
            headers=headers
        )

        if response.status_code not in [200, 201]:
            raise Exception(f"Failed to populate item {item.get('id', 'unknown')}: {response.text}")

        return response.json()

    def download_image_as_base64(self, image_url: str, max_size: int = 512, quality: int = 85) -> str:
        try:

            response = requests.get(image_url, timeout=30)
            response.raise_for_status()

            image = Image.open(io.BytesIO(response.content))

            if image.mode != 'RGBA':
                image = image.convert('RGBA')

            width, height = image.size
            if max(width, height) > max_size:
                if width > height:
                    new_width = max_size
                    new_height = int((height * max_size) / width)
                else:
                   new_height = max_size
                   new_width = int((width * max_size) / height)

                image = image.resize((new_width, new_height), Image.Resampling.LANCZOS)
                print(f"✓ Resized image from {width}x{height} to {new_width}x{new_height}")

            buffer = io.BytesIO()
            image.save(buffer, format='PNG', optimize=True)
            compressed_data = buffer.getvalue()

            image_data = base64.b64encode(compressed_data).decode('utf-8')

            base64_image = f"data:image/png;base64,{image_data}"

            print(f"✓ Image processed and converted to base64 ({len(image_data)} chars, {len(compressed_data)} bytes)")
            return base64_image

        except Exception as e:
            print(f"✗ Failed to download/process image {image_url}: {str(e)}")
            raise Exception(f"Image processing failed: {str(e)}")

    def upload_villager_image(self, villager_id: str, image_type: str, image_data: str) -> Dict:
        try:
            headers = {
                'Authorization': f'Bearer {self.system_token}',
                'Content-Type': 'application/json'
            }

            url = f"{self.api_base_url}/villager/{villager_id}/img/{image_type}"

            response = self.session.post(
                url,
                json={"image_data": image_data},
                headers=headers
            )

            if response.status_code not in [200, 201]:
                raise Exception(f"Failed to upload image: {response.text}")

            print(f"✓ Image uploaded successfully: {image_type}")
            return response.json()

        except Exception as e:
            print(f"✗ Failed to upload image {image_type}: {str(e)}")
            raise

    def update_villager_house_info(self, villager_id: str, house_data: Dict) -> Dict:
        try:
            headers = {
                'Authorization': f'Bearer {self.system_token}',
                'Content-Type': 'application/json'
            }

            url = f"{self.api_base_url}/villager/{villager_id}"

            response = self.session.put(
                url,
                json={"house": house_data},
                headers=headers
            )

            if response.status_code not in [200, 201]:
                raise Exception(f"Failed to update house info: {response.text}")

            print(f"✓ House info updated successfully")
            return response.json()

        except Exception as e:
            print(f"✗ Failed to update house info: {str(e)}")
            raise

    def update_villager_names(self, villager_id: str, names_data: Dict) -> Dict:
        try:
            headers = {
                'Authorization': f'Bearer {self.system_token}',
                'Content-Type': 'application/json'
            }

            url = f"{self.api_base_url}/villager/{villager_id}"

            response = self.session.put(
                url,
                json={"name": names_data},
                headers=headers
            )

            if response.status_code not in [200, 201]:
                raise Exception(f"Failed to update names: {response.text}")

            print(f"✓ Names updated successfully")
            return response.json()

        except Exception as e:
            print(f"✗ Failed to update names: {str(e)}")
            raise

    def get_fishes_from_api(self) -> List[Dict]:
        headers = {
            'Authorization': f'Bearer {self.system_token}',
            'Content-Type': 'application/json'
        }

        response = self.session.get(
            f"{self.api_base_url}/fish",
            headers=headers
        )

        if response.status_code != 200:
            raise Exception(f"Failed to fetch fishes from API: {response.text}")

        response_data = response.json()
        fishes = response_data.get('fishes', [])
        print(f"Fetched {len(fishes)} fishes from API")
        return fishes

    def update_fish_names(self, fish_id: str, names_data: Dict) -> Dict:
        try:
            headers = {
                'Authorization': f'Bearer {self.system_token}',
                'Content-Type': 'application/json'
            }

            url = f"{self.api_base_url}/fish/{fish_id}"

            response = self.session.put(
                url,
                json={"name": names_data},
                headers=headers
            )

            if response.status_code not in [200, 201]:
                raise Exception(f"Failed to update fish names: {response.text}")

            print(f"✓ Fish names updated successfully")
            return response.json()

        except Exception as e:
            print(f"✗ Failed to update fish names: {str(e)}")
            raise


class BaseWebPopulator(BasePopulator):
    """Base class for web scraping populators"""

    def __init__(self):
        super().__init__()
        self.session.headers.update({
            'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        })

    @abstractmethod
    def scrape_nookipedia_data(self, villager_names: List[str]) -> Dict:
        pass

    @abstractmethod
    def enhance_villager_data(self, villagers: List[Dict], nookipedia_data: Dict) -> List[Dict]:
        pass