# lab

### 📢 안내
1. 오른쪽 상단의 **[Code]** ->  **[Codespaces]** 를 눌러 💻코딩 환경을 만드세요.
2. `main.cpp` 파일을 열어 📜내용을 확인하고 ⌨️코딩하세요.
3. 🛠️컴파일 및 ▶️실행
- ⌨️ 📟터미널에서 아래 명령어로 컴파일하고 실행해보세요.
   - `g++ main.cpp -o main && ./main`
- 🖱️ 혹은 🧠Microsoft의 'C/C++ Extention Pack' 확장을 설치했으면
   - 상단의  **[▷ (Run)]** 버튼을 눌러 [C/C++: g++ 활성 파일 빌드 및 디버그] 컴파일하고
   - 결과는 📟터미널에서 확인하세요.
- 📊동적 메모리 누수 확인을 포함하여 컴파일 및 실행: AddressSanitizer (ASan)
   - `g++ -fsanitize=address -g main.cpp -o main && ./main`
4. 📟터미널에서 다음 명령어로 💯채점 스크립트를 실행해 볼 수 있습니다.
   - `chmod +x scoring.sh && ./scoring.sh`
  
### 📤 제출
- 🖱️ 왼쪽 'Source Control' 탭에서 메시지를 적고 **[Commit & Push]** 하세요.
- ⌨️ 혹은 📟터미널에서 `git add . && git commit -m "message" && git push` 하세요.
  - 이때 `"message"`는 커밋 내용 (예: ✅과제완료, 🐛수정내용, ✨추가, 🔥삭제, 🚀제출 등등)
- **[Codespaces]** 에서 **[Commit & Push]** 가 안될 경우, 직접 github repository의 `main.cpp`에서 코드를 편집한 후 **[Commit]** 하세요.

### 🏁실습 종료 후 
- 🌐 GitHub Sign out 🚶‍♂️
- 🔑 Windows 자격 증명 삭제 🗑️
- 🔒 세션 및 쿠키 정리

## 📌참고
   - 💻 Codespaces: 언제 어디서나 웹브라우저로 접속해 바로 코딩할 수 있는 클라우드 개발 컴퓨터
      - 💾 Save: 현재 코드 파일 하나하나를 가상 컴퓨터인 Codespace안에 저장 (자동저장됨)
         - 💡 Ctrl + S를 누르면 수동으로 저장할 수 있습니다.
      - 📸 Commit: 현재 전체 상태를 기록 (타임머신: 언제든 특정 커밋 시점으로 되돌릴 수 있음)
      - 📥 Staging: 커밋할 파일들을 '커밋 대기 명단'에 올림
      - 💬 Message: 커밋 내용을 짧게 적으면 됩니다. (예: ✅과제완료, 🐛수정내용, ✨추가, 🔥삭제, 🚀제출 등등)   
      - ⬆️ Push: 서버에 올리기 ⚠️ Codespace 삭제 전 반드시 push를 확인하세요.
      - 🔄 Sync: 서버와 내 상태를 똑같이 동기화
   - 📟 Terminal: 텍스트를 통해 컴퓨터와 소통하는 '창(윈도우)' 
      - ⌨️ Bash 명령어: Unix 계열 운영체제(Linux, macOS 등)의 기본 쉘(Shell)인 Bash(Bourne Again SHell)에서 실행하는 텍스트 기반의 지시어         
         - `g++ main.cpp -o main`: g++로 main.cpp를 컴파일, 출력(output)파일 이름은 main
            - g++: GNU 프로젝트에서 만든 C++ 컴파일러
            - `-fsanitize=address`: 메모리 검사 기능인 addressSanitizer (ASan) 활성화
            - `-g`: 디버깅 심볼 (소스코드의 줄 번호와 변수 이름 같은 디버깅 정보) 포함

         - `./main`: 현재 폴더(./)에 있는 main을 실행
         - `&&`: 논리 AND 연산자로, 앞의 명령어가 성공했을 때만 뒤의 명령어를 실행하는 명령 연결자
         - `chmod +x scoring.sh && ./scoring.sh`: scoring.sh에 대해 실행(eXecute) 가능한 권한을 추가(+)하고 scoring.sh를 실행
            - .sh: Unix 계열 운영체제에서 사용되는 쉘 스크립트(Shell Script) 파일
               - 텍스트 기반의 명령어들을 묶어 쉘(Terminal)에서 한 번에 실행
   - 📈 git: 컴퓨터 파일의 변경 사항을 추적하고 여러 명의 사용자들 간에 해당 파일 작업을 조율하기 위한 분산 버전 관리 시스템(DVCS)
      - git 명령어 
         - `git status`: 현재 작업 디렉토리의 상태(수정된 파일, staging 파일 등)를 확인
         - `git add .`: 전체 변경 사항을 staging
         - `git commit -m "message"`: staging 파일들을 커밋 내용을 적어 커밋
         - `git push`: 로컬에서 만든 커밋들을 원격 저장소로 보냄
   - 🧠 Microsoft의 'C/C++ Extention Pack' 확장: 코드 자동 완성(IntelliSense), 디버깅 도구 등 편집 편의 기능을 제공

