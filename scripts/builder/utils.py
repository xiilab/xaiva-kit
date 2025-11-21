"""
유틸리티 함수 모듈

콘솔 출력 관련 유틸리티 함수들을 제공합니다.
"""

import sys


def print_header(text: str) -> None:
    """헤더 출력"""
    print(f"\n{'=' * 80}")
    print(f"  {text}")
    print(f"{'=' * 80}\n")


def print_section(text: str) -> None:
    """섹션 헤더 출력"""
    print(f"\n--- {text} ---")


def print_error(text: str) -> None:
    """에러 메시지 출력"""
    print(f"\n❌ ERROR: {text}", file=sys.stderr)


def print_warning(text: str) -> None:
    """경고 메시지 출력"""
    print(f"\n⚠️  WARNING: {text}")


def print_success(text: str) -> None:
    """성공 메시지 출력"""
    print(f"\n✅ {text}")