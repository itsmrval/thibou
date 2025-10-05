#!/usr/bin/env python3
"""
Global application for populating and enhancing data from Nookipedia
Usage: python app.py [type] [options]
Examples:
  python app.py villagers, fishes
  python app.py <> --avoid-enhancements
  python app.py <> --avoid-translations
"""

import sys
import argparse
from typing import Dict, Any
from dotenv import load_dotenv

load_dotenv()

class GlobalPopulateApp:
    def __init__(self):
        self.available_types = {
            'villagers': 'villagers',
            'fishes': 'fishes',
            'bugs': 'bugs',
            'fossils': 'fossils',
        }

    def get_help(self) -> str:
        help_text = """
            Usage: python app.py [TYPE] [OPTIONS]

            Types:
            villagers                    - Populate villagers and enhance with house and name data
            fishes                       - Populate fishes from Nookipedia API
            bugs                         - Populate bugs from Nookipedia API
            fossils                      - Populate fossils from Nookipedia API

            Options for villagers:
            --avoid-enhancements        - Skip house enhancements (only populate base data)
            --avoid-translations        - Skip name translations (populate + house only)
            --avoid-rank-enhancements   - Skip popularity rank enhancements

            Options for fishes:
            --avoid-translations        - Skip name translations (only populate base data)

            Options for bugs:
            --avoid-translations        - Skip name translations (only populate base data)

        """
        return help_text.strip()

    def run(self, args: list = None):
        parser = argparse.ArgumentParser(
            description='Global populate thibou API from Nookipedia sources',
            formatter_class=argparse.RawDescriptionHelpFormatter,
            epilog=self.get_help()
        )

        parser.add_argument(
            'type',
            nargs='?',
            choices=list(self.available_types.keys()),
            help='data type to populate'
        )

        parser.add_argument(
            '--avoid-enhancements',
            action='store_true',
            help='skip house enhancements'
        )

        parser.add_argument(
            '--avoid-translations',
            action='store_true',
            help='skip name translations'
        )

        parser.add_argument(
            '--avoid-rank-enhancements',
            action='store_true',
            help='skip popularity rank enhancements'
        )

        parser.add_argument(
            '--help-types',
            action='store_true',
            help='show available types'
        )


        if args is None:
            args = sys.argv[1:]

        parsed_args = parser.parse_args(args)

        if parsed_args.help_types or not parsed_args.type:
            print(self.get_help())
            return

        data_type = self.available_types[parsed_args.type]

        try:
            if data_type == 'villagers':
                from villagers import VillagersGlobalPopulator
                populator = VillagersGlobalPopulator(
                    avoid_enhancements=parsed_args.avoid_enhancements,
                    avoid_translations=parsed_args.avoid_translations,
                    avoid_rank_enhancements=parsed_args.avoid_rank_enhancements
                )
                populator.run()
            elif data_type == 'fishes':
                from fishes import FishPopulator
                populator = FishPopulator(
                    avoid_translations=parsed_args.avoid_translations
                )
                populator.run()
            elif data_type == 'bugs':
                from bugs import BugPopulator
                populator = BugPopulator(
                    avoid_translations=parsed_args.avoid_translations
                )
                populator.run()
            elif data_type == 'fossils':
                from fossils import FossilPopulator
                populator = FossilPopulator()
                populator.run()
            else:
                print(f"Unknown type: {data_type}")
                sys.exit(1)

        except Exception as e:
            print(f"Error: {e}")
            sys.exit(1)

def main():
    app = GlobalPopulateApp()
    app.run()

if __name__ == "__main__":
    main()