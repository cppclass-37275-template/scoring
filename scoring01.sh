#!/bin/bash
# =============================================================================
# scoring.sh  ─  timeOfDay / alarm 과제 자동채점 (최종 통합본, 20점 만점)
# =============================================================================
# 항목별 배점:
#   [컴파일]       4점
#   [네임스페이스] 3점
#   [timeOfDay]    4점  
#   [alarm]        3점  
#   [예외 처리]     3점  (scoring1g의 동적 예외 기능 추가 🌟)
#   [main/출력]    3점  (유연한 출력 매칭)
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
# "namespace Xxx123" 또는 "namespace Xxx" 패턴 중 std 이외의 첫 번째를 사용
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
section "[네임스페이스 검증] (3점)"

# 4-1. 이름학번 패턴 네임스페이스 존재 여부 (1점)
NS_COUNT=$(grep -lE "namespace\s+[A-Za-z][A-Za-z0-9]+" \
           timeOfDay.h alarm.h main.cpp | wc -l)
if [[ $NS_COUNT -ge 2 ]]; then
    pass "사용자 정의 네임스페이스 사용 ($NS_COUNT/3 파일)" 1
else
    fail "사용자 정의 네임스페이스 미사용 또는 일부 누락"
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
CPP_USING=$(grep -E 'using\s+namespace' main.cpp 2>/dev/null | wc -l)
if [[ $HEADER_QUALIFIER -ge 1 ]] || [[ $CPP_USING -ge 1 ]]; then
    pass "헤더에 std:: 지정자 사용 / cpp에 using 지시자 사용" 1
else
    fail "헤더 std:: 지정자 또는 cpp using 지시자 확인 불가"
fi

# =============================================================================
# 5. [timeOfDay 클래스] 4점
# =============================================================================
section "[timeOfDay 클래스 구조 구현] (4점)"

# 5-1. private 멤버변수 hour, minute (1점)
if grep -qE 'int\s+hour' timeOfDay.h && grep -qE 'int\s+minute' timeOfDay.h; then
    pass "private int hour, int minute 선언" 1
else
    fail "hour 또는 minute 멤버변수 누락"
fi

# 5-2. 생성자에 기본값 설정 확인 (1점)
CTOR_LINE=$(grep -n 'timeOfDay\s*(' timeOfDay.h | head -5)
# '=\s*[0-9]+' 로 변경하여 0 이상의 모든 숫자를 허용하도록 수정
if echo "$CTOR_LINE" | grep -qE '=\s*[0-9]+' ; then
    pass "생성자 기본값 설정 확인" 1
else
    fail "생성자 기본값 미설정 (기본값 지정 패턴 미발견)"
fi

# 5-3. print const 정의 (1점)
if grep -qE 'void\s+print\s*\(\s*\)\s*const' timeOfDay.h; then
    pass "print() const 정의" 1
else
    fail "print() const 누락"
fi

# 5-4. get 접근함수 (getHour, getMinute) (1점)
if grep -qE 'getHour' timeOfDay.h && grep -qE 'getMinute' timeOfDay.h; then
    pass "getHour() / getMinute() 정의" 1
else
    fail "getHour 또는 getMinute 누락"
fi

# =============================================================================
# 6. [alarm 클래스] 3점
# =============================================================================
section "[alarm 클래스 구조 구현] (3점)"

# 6-1. timeOfDay wakeTime 및 bool inActive 멤버 (1점)
if grep -qE 'timeOfDay\s+wakeTime' alarm.h && grep -qE 'bool\s+inActive' alarm.h; then
    pass "필수 멤버 변수 선언 (wakeTime, inActive)" 1
else
    fail "wakeTime 또는 inActive 멤버 누락"
fi

# 6-2. print에 on/off 포함 (1점)
if grep -qE '"on"|"off"' alarm.h; then
    pass "print()에 on/off 문자열 포함" 1
else
    fail "print()에 on/off 없음"
fi

# 6-3. wakeTime 참조 반환 접근함수 (1점)
if grep -qE 'timeOfDay\s*&' alarm.h; then
    pass "wakeTime 참조 반환 접근함수 (&)" 1
else
    fail "wakeTime 참조 반환 접근함수 누락"
fi

# =============================================================================
# 7. [예외 처리 실제 검증] 3점 🌟 (scoring1g 기능 이식 및 업그레이드)
# =============================================================================
section "[예외 처리 동적 검증] (3점)"

if [[ "$DETECTED_NS" == "UNKNOWN" ]]; then
    fail "네임스페이스가 감지되지 않아 예외 처리 테스트를 건너넙니다."
else
    # 무효한 시간(25시)을 주입한 독립적인 예외 테스트 파일 생성
    cat << EOF > "$BUILD_DIR/test_exception.cpp"
#include "timeOfDay.h"
#include <iostream>
int main() {
    try {
        ${DETECTED_NS}::timeOfDay invalidTime(25, 0);
    } catch (...) {
        return 1; // 예외 발생 시 정상 catch 처리
    }
    return 0; 
}
EOF

    (cd "$BUILD_DIR" && g++ -std=c++17 test_exception.cpp -o test_exc_prog 2>/dev/null)
    
    if [[ -f "$BUILD_DIR/test_exc_prog" ]]; then
        # 실행 후 종료 코드 확인 (std::exit(1) 혹은 catch를 통해 1이 반환되는지 확인)
        timeout 3 "$BUILD_DIR/test_exc_prog"
        EXC_EXIT=$?
        
        if [[ $EXC_EXIT -eq 1 ]]; then
            pass "잘못된 입력(25시)에 대해 시스템이 안전하게 종료 코드 1을 반환함" 3
        else
            fail "비정상 입력 시 프로그램이 exit code 1로 종료되지 않음 (수행 결과: $EXC_EXIT)"
        fi
    else
        fail "예외 테스트 코드 컴파일 실패 (timeOfDay 구조 혹은 파일 포함 관계 오류)"
    fi
fi

# =============================================================================
# 8. [main / 출력] 3점 (실행 출력 검증)
# =============================================================================
section "[main 및 실행 출력 검증] (3점)"

if [[ "$COMPILED" == false ]]; then
    fail "컴파일 실패로 실행 채점 생략"
else
    # 8-1. compareTimeOfDay 비멤버함수 정의 (1점)
    if grep -qE 'compareTimeOfDay' main.cpp && grep -qE 'const\s+timeOfDay\s*&' main.cpp; then
        pass "compareTimeOfDay(const timeOfDay&, const timeOfDay&) 정의" 1
    else
        fail "compareTimeOfDay 비멤버함수 누락 또는 참조(const &) 미사용"
    fi

    # 실행 출력 캡처
    ACTUAL_OUT=$(echo "" | timeout 5 "$BINARY" 2>/dev/null)
    RUN_EXIT=$?

    if [[ $RUN_EXIT -ne 0 ]]; then
        fail "실행 중 런타임 에러 발생 (exit code: $RUN_EXIT)"
    else
        info "실제 프로그램 출력결과:"
        echo "$ACTUAL_OUT" | sed 's/^/    /'

        # 8-2. 알람 출력 포맷 검증 (1점)
        # 00:00 alarm is off 또는 on 패턴이 존재하는지 유연하게 검사
        if echo "$ACTUAL_OUT" | grep -qE '[0-9]{2}:[0-9]{2}\s+alarm\s+is\s+(on|off)'; then
            pass "알람 기본 출력 포맷 일치 (HH:MM alarm is on/off)" 1
        else
            fail "알람 출력 포맷 불일치 (예상 패턴: 'XX:XX alarm is on/off')"
        fi

        # 8-3. 비교 결과 출력 확인 (1점)
        if echo "$ACTUAL_OUT" | grep -qE '(same|different)'; then
            pass "compareTimeOfDay 결과 출력 확인 (same 또는 different)" 1
        else
            fail "출력결과에 'same' 또는 'different' 문구 누락"
        fi
    fi
fi

# =============================================================================
# 최종 점수 출력
# =============================================================================
echo -e "\n${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BOLD}  최종 합산 점수: ${CYAN}$TOTAL${RESET}${BOLD} / $MAX${RESET}"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

# 임시 빌드 디렉토리 삭제 정리
rm -rf "$BUILD_DIR"

# GitHub Classroom 호환용 exit code
if [[ $TOTAL -ge $MAX ]]; then
    exit 0
else
    exit 1
fi
