# RaceMP
> ## A racing mod for [BeamMP](https://beammp.com/)

Uses BeamNGTriggers as checkpoints and racing bounderies

Includes tracks from West Coast, USA, Automation Test Track, Hirochi Raceway, and way more. 

# Installation
Download latest release `RaceMP.zip` in [Releases](https://github.com/AbhiMayadam/RaceMP/releases)

Unzip `RaceMP.zip` into the root of your BeamMP server

# Usage
### Interaction uses chat commands:
* `/list` to list tracks

* `/set` to set race paramaters
    * `laps=n` where `n` is the number of laps
    * `track=trackName` where `trackName` is the name of a track from `/list`
    * `raceName=name` where `name` is the name of the race (shown on the leaderboard)
* `/start` to reset laps and start a countdown

# Making a track in BeamNG Drive
### Prerequisites
Clone this repository first with `git clone https://github.com/AbhiMayadam/RaceMP.git`. 
Install 7-Zip and add its install folder to Path. [Here is a guide on Stack Overflow.](https://stackoverflow.com/questions/44272416/how-to-add-a-folder-to-path-environment-variable-in-windows-10-with-screensho)
  1. Opening World Editor
  2. Make a new group in Scene Tree.
  3. Opening up Asset Browser and importing BeamMP triggers.prefab.json (at camera or at origin is fine).
  4. Move the imported prefab to the new group (mainly for organization's sake)
  5. Unpack the prefab and move the out of bounds, startstop, and lapsplit items out of the prefab to the folder you just made. (Again, for organization's sake so you don't overwrite your template.)
  6. Delete the old prefab.
  7. Drag startStop to your start/finish line, or if you are doing a sprint race, put the start trigger at the start line, and the stop trigger at the finish line. Delete the one you aren't using. (THIS IS MANDATORY)
  8. Put outOfBounds markers across areas that you don't want people to run. (You can duplicate these, and these are not necessary)
  9. Put lapSplit markers wherever you want to record splits/sectors. (You can duplicate these if you need more, just try to put them in order (like lapSplit1 goes before lapSplit 2 etc)
  10. Make the triggers as wide and as tall as necessary. I would recommend making the trigger wider than you'd expect to reduce the chances of the racers not being picked up by the triggers. 
  11. You can add other assets to the track like tire bundles, flags to denote splits etc. if you want it to be loaded alongside the race markers. I would recommend putting it in the group with all the markers.
  12. Highlight all the markers and every other race asset you used and pack into prefab. Name it something that is memorable and short. Save it to a folder (this starts out in your BeamNG AppData folder), and I recommend making a folder in this main level, and saving tracks in that. Call it "prefab_tracks" or something.
  13. Once the prefab is saved, do not save the level, and close it, we don't want any theoretical conflicts.
  14. Go to your BeamMP AppData folder `%appdata%\..\Local\BeamNG.drive` and go to the levels folder. Copy your modified map folder (ex. the ks_spa folder) to the `RaceMP\Resources\Client\levels` folder. (This folder is located in the repository you cloned.)
  15. Enter your modified map folder, make a "multiplayer" folder and copy your track prefab.json file into this. Your final folder should have a "main" folder, a "multiplayer" folder, and a main.decals.json folder. The [ks_spa folder](https://github.com/AbhiMayadam/RaceMP/tree/main/Resources/Client/levels/ks_spa) has the correct layout if you need an example.
  16. Run the compress.bat script and it will make a .zip that contains all of the server side code, the client side code, and the maps. Put this in your server following the installation instructions.

  Спасибо Funky7Monkey за то, что изначально создали мод. Если вы хотите перейти к их оригинальному репозиторию Gitea, вы можете сделать это здесь. https://git.funky7monkey.moe/funky7monkey/RaceMP. Их Gitea размещается самостоятельно и иногда выходит из строя, так что имейте это в виду. Мой первоначальный доступ к этому репозиторию на Github - это тот же исходный код, так что вы можете скачать его, если захотите.  

  Спасибо Lakota Lewulf за то, что предоставили мне свои макеты для нескольких треков, так что мне не нужно так много работать над созданием треков. Я буду постепенно добавлять треки в этот репозиторий по мере того, как буду делать больше для различных мероприятий. Если вы уже создали какие-то из них и хотите, чтобы они были добавлены в этот репозиторий, пожалуйста, не стесняйтесь сообщать об этом. Также, если у вас есть какие-либо вопросы, пожалуйста, сообщите об этом, и я постараюсь сделать все возможное, чтобы решить их. Это не моя кодовая база, и мои знания lua практически отсутствуют, но я попробую.




---

### Шаг 1: Откройте Редактор Мира (World Editor)
### Шаг 2: Создание и размещение триггеров
### Шаг 3: Правильное именование триггеров (Самый важный шаг!)

Клиентский скрипт ищет триггеры с **очень конкретными именами**. Если имя будет неправильным, скрипт его не увидит.

В окне редактора выберите ваш триггер. Справа, в окне **"Inspector"** (Инспектор), найдите поле **"Name"** и впишите туда одно из следующих имен:

#### Обязательные триггеры для любой трассы:

*   **`startStop`**
    *   **Назначение:** Универсальная линия Старта/Финиша. Когда игрок пересекает ее, скрипт либо начинает новый круг, либо заканчивает текущий.
    *   **Где ставить:** На финишной прямой. Сделайте триггер достаточно широким, чтобы покрыть всю дорогу.
    *   **Альтернатива:** Вы можете использовать два отдельных триггера: `start` для старта и `stop` для финиша. Это полезно для кольцевых трасс, где линия старта и финиша находятся в разных местах.

*   **`lapSplit#`** (где `#` — это номер)
    *   **Назначение:** Промежуточные контрольные точки (сектора или сплиты). Они нужны для отслеживания времени по секторам.
    *   **Как называть:** `lapSplit1`, `lapSplit2`, `lapSplit3` и так далее. **Номер в имени определяет порядок, в котором их нужно проезжать!** `lapSplit1` должен быть первым чекпоинтом после старта.
    *   **Где ставить:** Равномерно распределите их по трассе. Для хорошей телеметрии нужно хотя бы 2-3 сплита на круг.

#### Опциональные, но важные триггеры:

*   **`inPit`**
    *   **Назначение:** Вход на пит-лейн. Когда игрок пересекает этот триггер, скрипт активирует логику пит-стопа (например, включает ограничитель скорости).
    *   **Где ставить:** В самом начале пит-лейна.

*   **`outPit`**
    *   **Назначение:** Выход с пит-лейна.
    *   **Где ставить:** В конце пит-лейна, перед выездом на основную трассу.

*   **`outOfBounds`**
    *   **Назначение:** Штраф за срезку (выезд за пределы трассы). Когда игрок пересекает этот триггер, ему начисляется небольшой штраф и добавляется время.
    *   **Где ставить:** В местах, где можно срезать поворот (на внутренней части поворотов) или в зонах вылета. Разместите несколько таких триггеров по всей трассе.

*   **`outOfLap`**
    *   **Назначение:** Серьезное нарушение, которое аннулирует весь круг.
    *   **Где ставить:** В местах, где можно срезать огромный кусок трассы.

### Шаг 4: Сохранение триггеров как Prefab (Префаб)

Чтобы не изменять оригинальный файл карты, а также чтобы сервер мог легко загружать вашу гоночную разметку, ее нужно сохранить как отдельный файл-префаб.

1.  В окне редактора **"Scene Tree"** (Дерево сцены) найдите все созданные вами триггеры.
2.  Зажмите **Ctrl** и кликните на каждый из них, чтобы выбрать их все одновременно.
3.  В верхнем меню редактора выберите **File -> Export Selected as Prefab...** (Файл -> Экспортировать выбранное как Prefab...).
4.  **Куда сохранять (Очень важно!):** Вам нужно сохранить файл в специальную папку внутри папки с картой. Путь должен быть таким:
    `levels/имя_вашей_карты/multiplayer/`
5.  **Название файла:** Дайте ему осмысленное имя, например, `MyRaceLayout.prefab.json`.

### Шаг 5: Настройка сервера

Теперь, когда у вас есть готовый файл с разметкой, вам нужно сказать серверу, чтобы он его загрузил.

1.  Запустите сервер.
2.  В игровом чате напишите команду `/set`, указав имя вашего файла (без `.prefab.json`):
    `/set track=MyRaceLayout`

После этого сервер отправит всем клиентам команду загрузить этот префаб, и все ваши триггеры появятся на карте. Гонка готова к старту!

---

### Практический пример для простой трассы:

1.  Создаем триггер **`startStop`** на финишной прямой.
2.  Создаем триггер **`lapSplit1`** после первого поворота.
3.  Создаем триггер **`lapSplit2`** на середине обратной прямой.
4.  Создаем несколько триггеров **`outOfBounds`** на внутренней части самых очевидных для срезки поворотов.
5.  Выделяем все 4+ триггера и сохраняем их как `levels/italy/multiplayer/MyItalyRace.prefab.json`.
6.  На сервере пишем команду: `/set track=MyItalyRace laps=3`.

Готово! Теперь у вас есть рабочая гоночная трасса.