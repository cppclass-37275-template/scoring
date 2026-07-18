#!/bin/bash

TOTAL_SCORE=0
echo "=================================================="
echo "          [C++ 기말고사 자동 채점 프로그램]        "
echo "=================================================="

# 1. 컴파일 및 실행 결과 테스트 (1점 만점)
echo -n "1. 실행 및 결과 검증 (1점): "
g++ main.cpp -o main_test &> /dev/null

if [ $? -ne 0 ]; then
    echo "0점 (컴파일 실패)"
else
    # 예상되는 표준 출력 저장
    cat << 'EOF' > expected_output.txt
[Kim] Entry 10:30, In Use
[Lee] Entry 13:30, Exit 15:00, Fee: 3600 won
[Park] Entry 09:00, In Use
(Monthly Pass / Membership Fee: 50000 won)
[Choi] Entry 09:00, Exit 18:00, Fee: 0 won
(Monthly Pass / Membership Fee: 50000 won)
[Jung] Entry 23:30, Exit 23:30, Fee: 0 won
[Kang] Entry 23:55, Exit 01:55, Fee: Exit time cannot be earlier than Entry time.
EOF

    ./main_test > student_output.txt 2>&1
    
    # 공백 제거 후 내용 비교
    diff -w expected_output.txt student_output.txt &> /dev/null
    if [ $? -eq 0 ]; then
        echo "1점 (출력 결과 완벽 일치)"
        TOTAL_SCORE=$((TOTAL_SCORE + 1))
    else
        echo "0점 (컴파일은 성공했으나 출력 결과 불일치)"
        TOTAL_SCORE=$((TOTAL_SCORE + 0))
    fi
    rm -f expected_output.txt student_output.txt main_test
fi

# 2. 네임스페이스 체크 (1점)
echo -n "2. 네임스페이스 정의 체크 (1점): "
ns_check=0
grep -E "namespace[[:space:]]+[A-Za-z0-9]+" exceptionMessage.h &> /dev/null && ((ns_check++))
grep -E "namespace[[:space:]]+[A-Za-z0-9]+" monthlyStudyCafe.h &> /dev/null && ((ns_check++))
grep -E "namespace[[:space:]]+[A-Za-z0-9]+" studyCafe.h &> /dev/null && ((ns_check++))

if [ $ns_check -eq 3 ]; then
    echo "1점 (모든 헤더에 네임스페이스 적용됨)"
    TOTAL_SCORE=$((TOTAL_SCORE + 1))
else
    echo "0점 (일부 헤더에 네임스페이스 누락)"
fi

# 3. timeOfDay.h 연산자 오버로딩 체크 (1점)
echo -n "3. timeOfDay 연산자(>, -) 구현 (1점): "
if grep -E "int[[:space:]]+operator-[[:space:]]*\(" timeOfDay.h &> /dev/null && \
   grep -E "bool[[:space:]]+operator>[[:space:]]*\(" timeOfDay.h &> /dev/null; then
    echo "1점 (연산자 정의 및 반환 타입 올바름)"
    TOTAL_SCORE=$((TOTAL_SCORE + 1))
else
    echo "0점 (연산자 누락 또는 미구현)"
fi

# 4. studyCafe.h 멤버변수 선언 체크 (1점)
echo -n "4. studyCafe 멤버변수 선언 (1점): "
if grep -q "userName" studyCafe.h && grep -q "entryTime" studyCafe.h && grep -q "exitTime" studyCafe.h; then
    echo "1점 (userName, entryTime, exitTime 존재)"
    TOTAL_SCORE=$((TOTAL_SCORE + 1))
else
    echo "0점 (일부 필수 멤버변수 누락)"
fi

# 5. studyCafe.h 생성자 및 가상소멸자 체크 (1점)
echo -n "5. studyCafe 생성자/가상소멸자 (1점): "
if grep -E "studyCafe[[:space:]]*\(" studyCafe.h &> /dev/null && \
   grep -q "virtual ~studyCafe" studyCafe.h; then
    echo "1점 (생성자 및 virtual 소멸자 확인)"
    TOTAL_SCORE=$((TOTAL_SCORE + 1))
else
    echo "0점 (가상 소멸자 또는 생성자 오류)"
fi

# 6. studyCafe.h calculateFee 함수 체크 (1점)
echo -n "6. studyCafe::calculateFee 가상함수 (1점): "
if grep -E "virtual[[:space:]]+int[[:space:]]+calculateFee" studyCafe.h &> /dev/null; then
    echo "1점 (구현 및 가상함수 지정 확인)"
    TOTAL_SCORE=$((TOTAL_SCORE + 1))
else
    echo "0점 (가상함수 선언 오류)"
fi

# 7. studyCafe.h print 함수 체크 (1점)
echo -n "7. studyCafe::print 가상함수 (1점): "
if grep -E "virtual[[:space:]]+void[[:space:]]+print" studyCafe.h &> /dev/null; then
    echo "1점 (확인)"
    TOTAL_SCORE=$((TOTAL_SCORE + 1))
else
    echo "0점 (미구현)"
fi

# 8. studyCafe.h input 가상함수 체크 (1점)
echo -n "8. studyCafe::input 가상함수 (1점): "
if grep -E "virtual[[:space:]]+void[[:space:]]+input" studyCafe.h &> /dev/null; then
    echo "1점 (확인)"
    TOTAL_SCORE=$((TOTAL_SCORE + 1))
else
    echo "0점 (미구현)"
fi

# 9. studyCafe.h 입력연산자(operator>>) 체크 (1점)
echo -n "9. studyCafe 입력연산자 (operator>>) (1점): "
if grep -q "operator>>" studyCafe.h || grep -q "operator>>" main01.cpp; then
    echo "1점 (확인)"
    TOTAL_SCORE=$((TOTAL_SCORE + 1))
else
    echo "0점 (미구현)"
fi

# 10. monthlyStudyCafe.h 오버라이딩 체크 (1점)
echo -n "10. monthlyStudyCafe 오버라이딩 버전 검증 (1점): "
if grep -E "int[[:space:]]+calculateFee[[:space:]]*\([[:space:]]*\)" monthlyStudyCafe.h &> /dev/null && \
   ! grep -Pzo "int\s+calculateFee\s*\(\s*\)\s*\{\s*\}" monthlyStudyCafe.h &> /dev/null; then
    echo "1점 (오버라이딩 로직 구현 확인)"
    TOTAL_SCORE=$((TOTAL_SCORE + 1))
else
    echo "0점 (기본 포맷 상태이거나 오버라이딩 미흡)"
fi

echo "--------------------------------------------------"
echo " ▶ 최종 채점 점수: $TOTAL_SCORE / 10 점"
echo "================================================--"
