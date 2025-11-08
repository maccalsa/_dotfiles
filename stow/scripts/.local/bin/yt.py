import os
import subprocess
import sys
import shutil

class EasyDownloader:
    def __init__(self):
        # Check for yt-dlp first, then fallback to youtube-dl
        if shutil.which('yt-dlp'):
            self.downloader = 'yt-dlp'
        elif shutil.which('youtube-dl'):
            self.downloader = 'youtube-dl'
        else:
            print("Error: Neither 'yt-dlp' nor 'youtube-dl' found in your PATH.")
            print("Please install one (preferable yt-dlp) using: pip install yt-dlp")
            input("Press Enter to exit...")
            sys.exit(1)

        print(f"Found downloader: {self.downloader}")

    def clear_screen(self):
        os.system('cls' if os.name == 'nt' else 'clear')

    def get_save_directory(self):
        print("\nWhere do you want to save the files?")
        print("Leave blank to use the current folder.")
        path = input("Path > ").strip()
        if path:
            # Expand user paths like ~/Downloads
            full_path = os.path.expanduser(path)
            if not os.path.exists(full_path):
                try:
                    os.makedirs(full_path)
                    return full_path
                except Exception as e:
                    print(f"Could not create directory: {e}")
                    return os.getcwd()
            return full_path
        return os.getcwd()

    def run_command(self, args, cwd=None):
        print("\n--- Starting Download ---")
        # Using shell=True for easier Windows compatibility in some environments,
        # but generally passing chosen args list is safer.
        try:
            subprocess.run([self.downloader] + args, cwd=cwd, check=True)
            print("\n--- Finished Successfully! ---")
        except subprocess.CalledProcessError as e:
            print(f"\n--- Error occurred during download (Code {e.returncode}) ---")
        except FileNotFoundError:
             print(f"\nError: Could not execute {self.downloader}. Is it definitely in your PATH?")

    def menu(self):
        while True:
            self.clear_screen()
            print(f"=== Easy YouTube Downloader Wrapper ({self.downloader}) ===")
            print("1. Best Quality Video (Auto-merge best video + best audio)")
            print("2. Audio Only (MP3 - High Quality)")
            print("3. Download entire playlist (Best Quality)")
            print("4. Download entire playlist (Audio Only MP3)")
            print("5. Custom Format (Advanced users)")
            print("Q. Quit")
            
            choice = input("\nSelect an option: ").lower()

            if choice == 'q':
                break

            if choice in ['1', '2', '3', '4', '5']:
                url = input("Enter the URL: ").strip()
                if not url:
                    continue
                
                save_dir = self.get_save_directory()
                base_args = []

                # Basic output template: Title - ID.extension
                # This prevents duplicate overwrites if videos have same titles
                output_template = '%(title)s [%(id)s].%(ext)s'
                base_args.extend(['-o', output_template])

                # If you have ffmpeg installed, this ensures standard workable formats
                # if not needed, these can sometimes be omitted, but recommended.
                
                if choice == '1':
                    # Best video and best audio, merge them. 
                    # Fallback to 'best' single file if merging fails (e.g. no ffmpeg)
                    args = ['-f', 'bestvideo+bestaudio/best', '--merge-output-format', 'mp4', url]
                
                elif choice == '2':
                    # Extract audio (-x), convert to mp3, quality 0 (best VBR)
                    args = ['-x', '--audio-format', 'mp3', '--audio-quality', '0', url]

                elif choice == '3':
                    # Playlist best quality. 
                    # --yes-playlist is default usually, but good to be explicit if url is ambiguous
                    args = ['--yes-playlist', '-f', 'bestvideo+bestaudio/best', url]

                elif choice == '4':
                    # Playlist audio only
                    args = ['--yes-playlist', '-x', '--audio-format', 'mp3', '--audio-quality', '0', url]

                elif choice == '5':
                    # Let user type their own format string
                    print("\nCommon formats: 'best', 'worst', 'mp4', 'm4a'")
                    print("Specific resolution: 'bestvideo[height<=1080]+bestaudio/best'")
                    fmt = input("Enter format string: ")
                    args = ['-f', fmt, url]

                final_cmd = base_args + args
                
                # Show the user what we are about to run (educational)
                print(f"\nRunning command: {self.downloader} {' '.join(final_cmd)}")
                
                self.run_command(final_cmd, cwd=save_dir)
                input("\nPress Enter to return to menu...")

if __name__ == '__main__':
    try:
        app = EasyDownloader()
        app.menu()
    except KeyboardInterrupt:
        print("\nExiting...")
        sys.exit(0)
