from PySide6.QtCore import QCoreApplication
from class_widgets_2.core.schedule.model import Subject

DEFAULT_SUBJECTS = [
    {"id": "chinese", "name": "Chinese", "simplifiedName": "CHN", "icon": "ic_fluent_book_20_regular", "color": "#FF5722", "isLocalClassRoom": True},
    {"id": "math", "name": "Mathematics", "simplifiedName": "Math", "icon": "ic_fluent_ruler_20_regular", "color": "#3F51B5", "isLocalClassRoom": True},
    {"id": "english", "name": "English", "simplifiedName": "Eng", "icon": "ic_fluent_text_list_abc_uppercase_ltr_20_filled", "color": "#2196F3", "isLocalClassRoom": True},
    {"id": "politics", "name": "Politics", "simplifiedName": "Civics", "icon": "ic_fluent_book_globe_20_regular", "color": "#9C27B0", "isLocalClassRoom": True},
    {"id": "history", "name": "History", "simplifiedName": "Hist", "icon": "ic_fluent_clock_20_regular", "color": "#795548", "isLocalClassRoom": True},
    {"id": "physics", "name": "Physics", "simplifiedName": "Phys", "icon": "ic_fluent_lightbulb_filament_20_regular", "color": "#00BCD4", "isLocalClassRoom": True},
    {"id": "chemistry", "name": "Chemistry", "simplifiedName": "Chem", "icon": "ic_fluent_hexagon_three_20_regular", "color": "#4CAF50", "isLocalClassRoom": True},
    {"id": "biology", "name": "Biology", "simplifiedName": "Bio", "icon": "ic_fluent_leaf_three_20_regular", "color": "#8BC34A", "isLocalClassRoom": True},
    {"id": "geography", "name": "Geography", "simplifiedName": "Geo", "icon": "ic_fluent_earth_20_regular", "color": "#009688", "isLocalClassRoom": True},
    {"id": "music", "name": "Music", "simplifiedName": "Mus", "icon": "ic_fluent_music_note_2_20_regular", "color": "#E91E63", "isLocalClassRoom": True},
    {"id": "art", "name": "Art", "simplifiedName": "Art", "icon": "ic_fluent_draw_shape_20_regular", "color": "#F44336", "isLocalClassRoom": True},
    {"id": "psychology", "name": "Psychology", "simplifiedName": "Psy", "icon": "ic_fluent_brain_sparkle_20_regular", "color": "#FF9800", "isLocalClassRoom": True},
    {"id": "pe", "name": "Physical Education", "simplifiedName": "PE", "icon": "ic_fluent_person_running_20_regular", "color": "#CDDC39", "isLocalClassRoom": False},
    {"id": "it", "name": "Information Technology", "simplifiedName": "IT", "icon": "ic_fluent_laptop_20_regular", "color": "#607D8B", "isLocalClassRoom": True},
    {"id": "generaltech", "name": "General Technology", "simplifiedName": "GenTech", "icon": "ic_fluent_wrench_settings_20_regular", "color": "#FF9800", "isLocalClassRoom": True},
    {"id": "elective", "name": "Elective", "simplifiedName": "Elective", "icon": "ic_fluent_sign_out_20_regular", "color": "#9E9E9E", "isLocalClassRoom": False},
    {"id": "selfstudy", "name": "Self Study", "simplifiedName": "Study", "icon": "ic_fluent_notebook_20_regular", "color": "#607D8B", "isLocalClassRoom": True},
    {"id": "club", "name": "Club", "simplifiedName": "Club", "icon": "ic_fluent_people_team_20_regular", "color": "#673AB7", "isLocalClassRoom": True},
    {"id": "classmeeting", "name": "Class Meeting", "simplifiedName": "Meeting", "icon": "ic_fluent_chat_20_regular", "color": "#3F51B5", "isLocalClassRoom": True},
    {"id": "weeklytest", "name": "Weekly Test", "simplifiedName": "Test", "icon": "ic_fluent_clipboard_20_regular", "color": "#FF5722", "isLocalClassRoom": True}
]

def get_default_subjects() -> list[Subject]:
    result = []
    for subj in DEFAULT_SUBJECTS:
        sub = Subject(
            id=subj["id"],
            name=QCoreApplication.translate("Subjects", subj["name"]),
            simplifiedName=QCoreApplication.translate("SubjectsSimplified", subj.get("simplifiedName", "")),
            teacher=subj.get("teacher", ""),
            icon=subj.get("icon", ""),
            color=subj.get("color", ""),
            location=subj.get("location", ""),
            isLocalClassroom=subj.get("isLocalClassRoom", True),
        )
        result.append(sub)
    return result

def translate_sources():
    # full names
    QCoreApplication.translate("Subjects", "Chinese")
    QCoreApplication.translate("Subjects", "Mathematics")
    QCoreApplication.translate("Subjects", "English")
    QCoreApplication.translate("Subjects", "Politics")
    QCoreApplication.translate("Subjects", "History")
    QCoreApplication.translate("Subjects", "Physics")
    QCoreApplication.translate("Subjects", "Chemistry")
    QCoreApplication.translate("Subjects", "Biology")
    QCoreApplication.translate("Subjects", "Geography")
    QCoreApplication.translate("Subjects", "Music")
    QCoreApplication.translate("Subjects", "Art")
    QCoreApplication.translate("Subjects", "Psychology")
    QCoreApplication.translate("Subjects", "Physical Education")
    QCoreApplication.translate("Subjects", "Information Technology")
    QCoreApplication.translate("Subjects", "General Technology")
    QCoreApplication.translate("Subjects", "Elective")
    QCoreApplication.translate("Subjects", "Self Study")
    QCoreApplication.translate("Subjects", "Club")
    QCoreApplication.translate("Subjects", "Class Meeting")
    QCoreApplication.translate("Subjects", "Weekly Test")
    QCoreApplication.translate("Subjects", "Economics")
    QCoreApplication.translate("Subjects", "Philosophy")
    QCoreApplication.translate("Subjects", "Computer Science")

    # simplified names
    QCoreApplication.translate("SubjectsSimplified", "CHN")
    QCoreApplication.translate("SubjectsSimplified", "Math")
    QCoreApplication.translate("SubjectsSimplified", "Eng")
    QCoreApplication.translate("SubjectsSimplified", "Civics")
    QCoreApplication.translate("SubjectsSimplified", "Hist")
    QCoreApplication.translate("SubjectsSimplified", "Phys")
    QCoreApplication.translate("SubjectsSimplified", "Chem")
    QCoreApplication.translate("SubjectsSimplified", "Bio")
    QCoreApplication.translate("SubjectsSimplified", "Geo")
    QCoreApplication.translate("SubjectsSimplified", "Mus")
    QCoreApplication.translate("SubjectsSimplified", "Art")
    QCoreApplication.translate("SubjectsSimplified", "Psy")
    QCoreApplication.translate("SubjectsSimplified", "PE")
    QCoreApplication.translate("SubjectsSimplified", "IT")
    QCoreApplication.translate("SubjectsSimplified", "GenTech")
    QCoreApplication.translate("SubjectsSimplified", "Elective")
    QCoreApplication.translate("SubjectsSimplified", "Study")
    QCoreApplication.translate("SubjectsSimplified", "Club")
    QCoreApplication.translate("SubjectsSimplified", "ClassMtg")
    QCoreApplication.translate("SubjectsSimplified", "Weekly")
    QCoreApplication.translate("SubjectsSimplified", "Econ")
    QCoreApplication.translate("SubjectsSimplified", "Philos")
    QCoreApplication.translate("SubjectsSimplified", "CS")
    QCoreApplication.translate("SubjectsSimplified", "Meeting")
    QCoreApplication.translate("SubjectsSimplified", "Test")
