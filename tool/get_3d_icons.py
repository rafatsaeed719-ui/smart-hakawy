"""بيتشغل في GitHub Actions: ينزّل أيقونات Fluent Emoji 3D (رخصة MIT) لمجلد assets/3d."""
import pathlib
import urllib.parse
import urllib.request

BASE = 'https://raw.githubusercontent.com/microsoft/fluentui-emoji/main/assets/'
ICONS = {
    'rocket': 'Rocket/3D/rocket_3d.png',
    'fire': 'Fire/3D/fire_3d.png',
    'trophy': 'Trophy/3D/trophy_3d.png',
    'star': 'Star/3D/star_3d.png',
    'glowing_star': 'Glowing star/3D/glowing_star_3d.png',
    'party': 'Party popper/3D/party_popper_3d.png',
    'books': 'Books/3D/books_3d.png',
    'speech': 'Speech balloon/3D/speech_balloon_3d.png',
    'microphone': 'Microphone/3D/microphone_3d.png',
    'headphone': 'Headphone/3D/headphone_3d.png',
    'brain': 'Brain/3D/brain_3d.png',
    'bullseye': 'Bullseye/3D/bullseye_3d.png',
    'memo': 'Memo/3D/memo_3d.png',
    'light_bulb': 'Light bulb/3D/light_bulb_3d.png',
    'crown': 'Crown/3D/crown_3d.png',
    'gem': 'Gem stone/3D/gem_stone_3d.png',
    'medal': '1st place medal/3D/1st_place_medal_3d.png',
    'sports_medal': 'Sports medal/3D/sports_medal_3d.png',
    'airplane': 'Airplane/3D/airplane_3d.png',
    'fork_knife': 'Fork and knife with plate/3D/fork_and_knife_with_plate_3d.png',
    'shopping': 'Shopping bags/3D/shopping_bags_3d.png',
    'briefcase': 'Briefcase/3D/briefcase_3d.png',
    'hospital': 'Hospital/3D/hospital_3d.png',
    'clapper': 'Clapper board/3D/clapper_board_3d.png',
    'soccer': 'Soccer ball/3D/soccer_ball_3d.png',
    'house': 'House with garden/3D/house_with_garden_3d.png',
    'sun': 'Sun/3D/sun_3d.png',
    'globe': 'Globe showing europe-africa/3D/globe_showing_europe-africa_3d.png',
    'seedling': 'Seedling/3D/seedling_3d.png',
    'graduation': 'Graduation cap/3D/graduation_cap_3d.png',
    'check': 'Check mark button/3D/check_mark_button_3d.png',
    'cross': 'Cross mark/3D/cross_mark_3d.png',
    'speaker': 'Speaker high volume/3D/speaker_high_volume_3d.png',
    'bookmark': 'Bookmark/3D/bookmark_3d.png',
    'heart': 'Red heart/3D/red_heart_3d.png',
    'waving': 'Waving hand/Default/3D/waving_hand_3d_default.png',
    'muscle': 'Flexed biceps/Default/3D/flexed_biceps_3d_default.png',
    'clap': 'Clapping hands/Default/3D/clapping_hands_3d_default.png',
    'thumbs_up': 'Thumbs up/Default/3D/thumbs_up_3d_default.png',
    'ear': 'Ear/Default/3D/ear_3d_default.png',
    'thinking': 'Thinking face/3D/thinking_face_3d.png',
    'smile': 'Smiling face with smiling eyes/3D/smiling_face_with_smiling_eyes_3d.png',
    'star_struck': 'Star-struck/3D/star-struck_3d.png',
    'sad': 'Confused face/3D/confused_face_3d.png',
    'pencil': 'Pencil/3D/pencil_3d.png',
    'chart': 'Chart increasing/3D/chart_increasing_3d.png',
    'calendar': 'Spiral calendar/3D/spiral_calendar_3d.png',
    'lock': 'Locked/3D/locked_3d.png',
    'puzzle': 'Puzzle piece/3D/puzzle_piece_3d.png',
    'family': 'People hugging/3D/people_hugging_3d.png',
    'turtle': 'Turtle/3D/turtle_3d.png',
    'rabbit': 'Rabbit/3D/rabbit_3d.png',
    'key': 'Key/3D/key_3d.png',
    'camera': 'Camera with flash/3D/camera_with_flash_3d.png',
    'hourglass': 'Hourglass not done/3D/hourglass_not_done_3d.png',
    'sparkles': 'Sparkles/3D/sparkles_3d.png',
    'compass': 'Compass/3D/compass_3d.png',
    'video': 'Video camera/3D/video_camera_3d.png',
    'robot': 'Robot/3D/robot_3d.png',
    'hundred': 'Hundred points/3D/hundred_points_3d.png',
    'gift': 'Wrapped gift/3D/wrapped_gift_3d.png',
    'map': 'World map/3D/world_map_3d.png',
}

out = pathlib.Path(__file__).resolve().parent.parent / 'assets' / '3d'
out.mkdir(parents=True, exist_ok=True)
ok, missing = 0, []
for key, path in ICONS.items():
    url = BASE + urllib.parse.quote(path)
    try:
        with urllib.request.urlopen(url, timeout=30) as r:
            (out / f'{key}.png').write_bytes(r.read())
        ok += 1
    except Exception as e:  # noqa: BLE001
        missing.append(f'{key} ({e})')
print(f'downloaded {ok}/{len(ICONS)}')
for m in missing:
    print('missing:', m)
