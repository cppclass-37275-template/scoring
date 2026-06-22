#!/bin/bash
# =============================================================================
# scoring.sh  ─  timeOfDay / alarm 과제 자동채점 (20점 만점)
# =============================================================================
# 항목별 배점:
#   [컴파일]       4점
#   [네임스페이스] 3점
#   [timeOfDay]    5점
#   [alarm]        4점
#   [main/출력]    4점
# =============================================================================

TOTAL=0
MAX=20

REQUIRED_FILES=("timeOfDay.h" "alarm.h" "main.cpp")
BUILD_DIR=$(mktemp -d)
BINARY="$BUILD_DIR/main"

# ── 색상 ──────────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

pass() { echo -e "  ${GREEN}[PASS]${RESET} $1 (+$2점)"; TOTAL=$((TOTAL + $2)); }
fail() { echo -e "  ${RED}[FAIL]${RESET} $1"; }
info() { echo -e "  ${YELLOW}[INFO]${RESET} $1"; }
section() { echo -e "\n${CYAN}${BOLD}▶ $1${RESET}"; }

# =============================================================================
# 0. 필수 파일 존재 확인
# =============================================================================
section "필수 파일 확인"
ALL_FILES=true
for f in "${REQUIRED_FILES[@]}"; do
    if [[ -f "$f" ]]; then
        pass "$f 존재" 0
    else
        fail "$f 없음"
        ALL_FILES=false
    fi
done

if [[ "$ALL_FILES" == false ]]; then
    echo -e "\n${RED}필수 파일이 없어 채점을 중단합니다.${RESET}"
    echo "최종 점수: 0 / $MAX"
    exit 1
fi

# 파일을 빌드 디렉토리로 복사
cp timeOfDay.h alarm.h main.cpp "$BUILD_DIR/"

# =============================================================================
# 1. 소스 파일 통합 (분석용)
# =============================================================================
ALL_SRC="$BUILD_DIR/all_src.txt"
cat timeOfDay.h alarm.h main.cpp > "$ALL_SRC"

# =============================================================================
# 2. 네임스페이스 감지 (학번포함 자동 추출)
# =============================================================================
# "namespace Xxx123" 패턴 중 std/HongGil 이외의 첫 번째를 사용
DETECTED_NS=$(grep -oE 'namespace\s+[A-Za-z][A-Za-z0-9]+' "$ALL_SRC" \
              | grep -v 'namespace std' \
              | head -1 \
              | awk '{print $2}')

if [[ -z "$DETECTED_NS" ]]; then
    DETECTED_NS="UNKNOWN"
fi
info "감지된 네임스페이스: ${BOLD}$DETECTED_NS${RESET}"

# =============================================================================
# 3. [컴파일] 4점
# =============================================================================
section "[컴파일] (4점)"

COMPILE_LOG=$(cd "$BUILD_DIR" && g++ -std=c++17 -Wall -Wextra \
              -o "$BINARY" main.cpp 2>&1)
COMPILE_EXIT=$?

if [[ $COMPILE_EXIT -eq 0 ]]; then
    pass "컴파일 성공" 4
    COMPILED=true
else
    fail "컴파일 실패"
    info "오류 내용:"
    echo "$COMPILE_LOG" | head -20
    COMPILED=false
fi

# =============================================================================
# 4. [네임스페이스] 3점
# =============================================================================
section "[네임스페이스] (3점)"

# 4-1. 이름학번 패턴 네임스페이스가 세 파일에 존재 (1점)
NS_COUNT=$(grep -lE "namespace\s+[A-Z][A-Za-z]+[0-9]+" \
           timeOfDay.h alarm.h main.cpp | wc -l)
if [[ $NS_COUNT -ge 2 ]]; then
    pass "이름+학번 형식 네임스페이스 사용 ($NS_COUNT/3 파일)" 1
else
    fail "이름+학번 형식 네임스페이스 미사용 또는 일부 누락"
fi

# 4-2. 헤더 파일에 using 지시자(using namespace) 없음 (1점)
HEADER_USING=$(grep -E '^\s*using\s+namespace' timeOfDay.h alarm.h 2>/dev/null)
if [[ -z "$HEADER_USING" ]]; then
    pass "헤더파일에 using namespace 없음" 1
else
    fail "헤더파일에 using namespace 사용 (금지)"
    info "위반 내용: $HEADER_USING"
fi

# 4-3. 헤더에서 std:: 지정자 사용 또는 cpp에서 블록 내 using 사용 (1점)
HEADER_QUALIFIER=$(grep -E 'std::' timeOfDay.h alarm.h 2>/dev/null | wc -l)
BLOCK_USING=$(grep -E '\{\s*using\s+namespace|using\s+namespace.*\{' main.cpp 2>/dev/null | wc -l)
# cpp 파일에서 함수/블록 범위 using (중괄호 안) - 단순히 using namespace가 있고 헤더엔 없으면 부분인정
CPP_USING=$(grep -E 'using\s+namespace' main.cpp 2>/dev/null | wc -l)
if [[ $HEADER_QUALIFIER -ge 1 ]] || [[ $CPP_USING -ge 1 ]]; then
    pass "헤더에 std:: 지정자 사용 / cpp에 using 지시자 사용" 1
else
    fail "헤더 std:: 지정자 또는 cpp using 지시자 확인 불가"
fi

# =============================================================================
# 5. [timeOfDay 클래스] 5점
# =============================================================================
section "[timeOfDay 클래스] (5점)"

# 5-1. private 멤버변수 hour, minute (1점)
if grep -qE 'int\s+hour' timeOfDay.h && grep -qE 'int\s+minute' timeOfDay.h; then
    pass "private int hour, int minute 선언" 1
else
    fail "hour 또는 minute 멤버변수 누락"
fi

# 5-2. testHour / testMinute 존재 (1점)
if grep -qE 'testHour' timeOfDay.h && grep -qE 'testMinute' timeOfDay.h; then
    pass "testHour / testMinute 정의" 1
else
    fail "testHour 또는 testMinute 누락"
fi

# 5-3. 생성자에 기본값 & test 호출 (1점)
CTOR_LINE=$(grep -n 'timeOfDay\s*(' timeOfDay.h | head -5)
if echo "$CTOR_LINE" | grep -qE '=\s*0' ; then
    pass "생성자 기본값 설정 확인" 1
else
    fail "생성자 기본값 미설정 (= 0 패턴 미발견)"
fi

# 5-4. print const + setw/setfill 또는 0패딩 (1점)
if grep -qE 'void\s+print\s*\(\s*\)\s*const' timeOfDay.h; then
    pass "print() const 정의" 1
else
    fail "print() const 누락"
fi

# 5-5. get 접근함수 (getHour, getMinute) (1점)
if grep -qE 'getHour' timeOfDay.h && grep -qE 'getMinute' timeOfDay.h; then
    pass "getHour() / getMinute() 정의" 1
else
    fail "getHour 또는 getMinute 누락"
fi

# =============================================================================
# 6. [alarm 클래스] 4점
# =============================================================================
section "[alarm 클래스] (4점)"

# 6-1. timeOfDay wakeTime 멤버 (1점)
if grep -qE 'timeOfDay\s+wakeTime' alarm.h; then
    pass "timeOfDay형 wakeTime 멤버 선언" 1
else
    fail "wakeTime 멤버 누락 또는 타입 오류"
fi

# 6-2. bool inActive (1점)
if grep -qE 'bool\s+inActive' alarm.h; then
    pass "bool inActive 멤버 선언" 1
else
    fail "inActive 멤버 누락"
fi

# 6-3. print에 on/off 포함 (1점)
if grep -qE '"on"|"off"' alarm.h; then
    pass "print()에 on/off 문자열 포함" 1
else
    fail "print()에 on/off 없음"
fi

# 6-4. wakeTime 참조 반환 접근함수 (1점)
if grep -qE 'timeOfDay\s*&' alarm.h; then
    pass "wakeTime 참조 반환 접근함수" 1
else
    fail "wakeTime 참조 반환 접근함수 누락"
fi

# =============================================================================
# 7. [main / 출력] 4점  (컴파일 성공 시에만)
# =============================================================================
section "[main 및 실행 출력] (4점)"

if [[ "$COMPILED" == false ]]; then
    fail "컴파일 실패로 실행 채점 생략"
else
    # 7-1. compareTimeOfDay 비멤버함수 정의 (1점)
    if grep -qE 'compareTimeOfDay' main.cpp && \
       grep -qE 'const\s+timeOfDay\s*&' main.cpp; then
        pass "compareTimeOfDay(const timeOfDay&, const timeOfDay&) 정의" 1
    else
        fail "compareTimeOfDay 비멤버함수 누락 또는 시그니처 오류"
    fi

    # 실행 출력 캡처 (stdin 없이)
    ACTUAL_OUT=$(echo "" | timeout 5 "$BINARY" 2>/dev/null)
    RUN_EXIT=$?

    if [[ $RUN_EXIT -ne 0 ]]; then
        fail "실행 중 오류 (exit code: $RUN_EXIT)"
        info "출력: $ACTUAL_OUT"
    else
        info "실제 출력:"
        echo "$ACTUAL_OUT" | sed 's/^/    /'

        # 7-2. 기본 alarm 출력: 00:00 alarm is off (1점)
        if echo "$ACTUAL_OUT" | grep -qE '00:00\s+alarm\s+is\s+off'; then
            pass "기본 alarm1 출력 (00:00 alarm is off)" 1
        else
            fail "기본 alarm1 출력 불일치 (예상: '00:00 alarm is off')"
        fi

        # 7-3. alarm2 출력: HH:MM alarm is on (1점)
        if echo "$ACTUAL_OUT" | grep -qE '[0-9]{2}:[0-9]{2}\s+alarm\s+is\s+on'; then
            pass "alarm2 출력 (XX:XX alarm is on)" 1
        else
            fail "alarm2 출력 불일치 (예상: 'XX:XX alarm is on')"
        fi

        # 7-4. same 또는 different 출력 (1점)
        if echo "$ACTUAL_OUT" | grep -qE '^(same|different)$'; then
            pass "compareTimeOfDay 결과 출력 (same/different)" 1
        else
            fail "same 또는 different 출력 없음"
        fi
    fi
fi

# =============================================================================
# 최종 점수
# =============================================================================
echo -e "\n${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BOLD}  최종 점수: ${CYAN}$TOTAL${RESET}${BOLD} / $MAX${RESET}"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

# GitHub Classroom 자동채점용 exit code
if [[ $TOTAL -ge $MAX ]]; then
    exit 0
else
    exit 1
fi
