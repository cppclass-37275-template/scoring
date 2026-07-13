#!/bin/bash

SCORE=0

echo "=========================================="
# 1. 빌드 성공 채점 (1점)
echo -n "[빌드 성공] 빌드를 시도합니다... "
#g++ -std=c++14 main.cpp -o test_prog 2>/dev/null
g++ -std=c++14 main.cpp -I. -o test_prog
if [ $? -eq 0 ]; then
    echo "성공 (+1)"
    SCORE=$((SCORE + 1))
else
    echo "실패 (+0)"
fi

# 2. timeOfDay.h 정적분석 (7점)
echo "------------------------------------------"
echo "[timeOfDay.h 정적 분석]"

#grep -q "operator++\s*(\s*)" timeOfDay.h && { echo "  - operator++ 전위 성공 (+1)"; SCORE=$((SCORE + 1)); } || echo "  - operator++ 전위 실패 (+0)"
#grep -q "operator++\s*(\s*int" timeOfDay.h && { echo "  - operator++ 후위 성공 (+1)"; SCORE=$((SCORE + 1)); } || echo "  - operator++ 후위 실패 (+0)"
    # operator++ 문과 return *this가 한 흐름에 있는지 확인 (패턴 완화)
    if grep -A 20 "operator++\s*(\s*)" timeOfDay.h | grep -q "return\s*\*this"; then
        echo "  - operator++ 전위 성공 (+1)"
        SCORE=$((SCORE + 1))
    else
        echo "  - operator++ 전위 실패 (+0)"
    fi

    # [수정] operator++ 후위 구현에 this가 포함되어 있는지 체크
    if grep -A 5 "operator++\s*(\s*int" timeOfDay.h | grep -q "this"; then
        echo "  - operator++ 후위 성공 (+1)"
        SCORE=$((SCORE + 1))
    else
        echo "  - operator++ 후위 실패 (+0)"
    fi
# operator와 += 사이에 공백(\s*)이 있어도 매칭되도록 수정
grep -q "operator\s*+=" timeOfDay.h && { echo "  - operator+= 성공 (+1)"; SCORE=$((SCORE + 1)); } || echo "  - operator+= 실패 (+0)"
grep -q "operator\s*>>" timeOfDay.h && { echo "  - operator>> 성공 (+1)"; SCORE=$((SCORE + 1)); } || echo "  - operator>> 실패 (+0)"
grep -q "operator\s*<<" timeOfDay.h && { echo "  - operator<< 성공 (+1)"; SCORE=$((SCORE + 1)); } || echo "  - operator<< 실패 (+0)"
grep -q "operator\s*==" timeOfDay.h && { echo "  - operator== 성공 (+1)"; SCORE=$((SCORE + 1)); } || echo "  - operator== 실패 (+0)"
grep -q "operator\s*+" timeOfDay.h && { echo "  - operator+ (이항) 성공 (+1)"; SCORE=$((SCORE + 1)); } || echo "  - operator+ (이항) 실패 (+0)"

# 3. alarm.h 정적분석 (3점)
echo "------------------------------------------"
echo "[alarm.h 정적 분석]"

grep -q "std::string" alarm.h && { echo "  - std::string 멤버 성공 (+1)"; SCORE=$((SCORE + 1)); } || echo "  - std::string 멤버 실패 (+0)"
grep -q "operator\s*>>" alarm.h && { echo "  - operator>> 성공 (+1)"; SCORE=$((SCORE + 1)); } || echo "  - operator>> 실패 (+0)"
grep -q "operator\s*<<" alarm.h && { echo "  - operator<< 성공 (+1)"; SCORE=$((SCORE + 1)); } || echo "  - operator<< 실패 (+0)"

# 4. timePtr.h 정적분석 (6점)
echo "------------------------------------------"
echo "[timePtr.h 정적 분석]"

grep -q "timePtr\s*(" timePtr.h && { echo "  - 생성자 성공 (+1)"; SCORE=$((SCORE + 1)); } || echo "  - 생성자 실패 (+0)"
grep -q "~timePtr" timePtr.h && { echo "  - 소멸자 성공 (+1)"; SCORE=$((SCORE + 1)); } || echo "  - 소멸자 실패 (+0)"
grep -q "const\s*timePtr\s*&" timePtr.h && { echo "  - 복사생성자 성공 (+1)"; SCORE=$((SCORE + 1)); } || echo "  - 복사생성자 실패 (+0)"
grep -q "operator\s*=\s*(\s*const" timePtr.h && { echo "  - 복사할당연산자 성공 (+1)"; SCORE=$((SCORE + 1)); } || echo "  - 복사할당연산자 실패 (+0)"

# [수정] && 직후 공백이나 변수명이 붙어있어도 매칭되도록 정규식 완화
grep -q "timePtr\s*(\s*timePtr\s*&&\s*[a-zA-Z0-9_]*\s*)" timePtr.h && { echo "  - 이동생성자 성공 (+1)"; SCORE=$((SCORE + 1)); } || echo "  - 이동생성자 실패 (+0)"
grep -q "operator\s*=\s*(\s*timePtr\s*&&\s*[a-zA-Z0-9_]*\s*)" timePtr.h && { echo "  - 이동할당연산자 성공 (+1)"; SCORE=$((SCORE + 1)); } || echo "  - 이동할당연산자 실패 (+0)"

# 5. 채점 드라이버 실행 분석 (3점)
echo "------------------------------------------"
echo "[채점 드라이버 실행 분석]"

if [ -f test_prog ]; then
    ./test_prog > run_output.txt

    # [수정] 특정 시간(10:30 등) 대신 'no time data'가 찍혔는지를 기준으로 이동(Move) 후 소유권 이전 검증
    if grep -q "no time data" run_output.txt; then
        echo "  - timePtr RoF 동작 성공 (+1)"
        SCORE=$((SCORE + 1))
    else
        echo "  - timePtr RoF 동작 실패 (+0)"
    fi

# [수정] main.cpp 소스 코드 내에 unique_ptr, make_unique, std::move가 모두 포함되어 있는지 검증
    if grep -q "unique_ptr" main.cpp && grep -q "make_unique" main.cpp && grep -q "std::move" main.cpp; then
        echo "  - unique_ptr 성공 (+1)"
        SCORE=$((SCORE + 1))
    else
        echo "  - unique_ptr 실패 (+0)"
    fi

# [수정] 모든 공백/줄바꿈을 제거하고 숫자 순서가 22220122인지 정확히 체크
    if [ "$(tr -d '[:space:]' < run_output.txt | grep -o '22220122')" = "22220122" ]; then
        echo "  - shared/weak_ptr 성공 (+1)"
        SCORE=$((SCORE + 1))
    else
        echo "  - shared/weak_ptr 실패 (+0)"
    fi
    
    rm -f run_output.txt test_prog
else
    echo "  - 빌드 실패로 인해 실행 분석을 수행할 수 없습니다 (+0)"
fi

echo "=========================================="
echo "최종 점수: $SCORE / 20"
echo "=========================================="
