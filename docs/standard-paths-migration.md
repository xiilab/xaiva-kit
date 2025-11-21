# 표준 경로 마이그레이션

## 개요

Xaiva Media 전용 경로(`/usr/local/xaiva_media`)를 제거하고 리눅스 표준 경로를 사용하도록 변경했습니다. 이를 통해 라이브러리 경로 문제를 최소화하고 시스템 표준을 따릅니다.

## 변경 날짜
2025-11-20

---

## 변경 사항

### 1. Dockerfile 수정

#### Before (변경 전)

```dockerfile
# 환경 변수 설정
ENV PATH="/usr/local/xaiva_media/bin:${PATH}"
ENV LD_LIBRARY_PATH="/usr/local/xaiva_media/lib:/usr/local/cuda/lib64:/usr/local/cuda/extras/CUPTI/lib64:/usr/local/cuda/include"

# 빌드 산출물 복사
COPY --from=builder /usr/local/xaiva_media/ /usr/local/xaiva_media/
```

#### After (변경 후)

```dockerfile
# 환경 변수 설정 (런타임)
# /usr/local/bin 과 /usr/local/lib 는 시스템 기본 PATH에 포함됨
ENV LD_LIBRARY_PATH="/usr/local/lib:/usr/local/cuda/lib64:/usr/local/cuda/extras/CUPTI/lib64"

# 빌드 산출물 복사 (표준 경로 사용)
COPY --from=builder /usr/local/lib/ /usr/local/lib/
COPY --from=builder /usr/local/bin/ /usr/local/bin/
COPY --from=builder /usr/local/include/ /usr/local/include/
RUN ldconfig
```

#### Xaiva Media 빌드 설정

```dockerfile
# CMAKE_INSTALL_PREFIX를 /usr/local 로 명시
RUN cd /tmp/xaiva-media && \
    mkdir -p build && cd build && \
    cmake -DCMAKE_INSTALL_PREFIX=/usr/local .. && \
    make -j$(nproc) && \
    make install && \
    ldconfig
```

### 2. 프리셋 JSON 수정

#### Before

```json
{
  "environment": {
    "LD_LIBRARY_PATH": "/usr/local/xaiva_media/lib:/usr/include:/usr/local/cuda/lib64:/usr/local/cuda/extras/CUPTI/lib64:/usr/local/cuda/include"
  }
}
```

#### After

```json
{
  "environment": {
    "LD_LIBRARY_PATH": "/usr/local/lib:/usr/local/cuda/lib64:/usr/local/cuda/extras/CUPTI/lib64"
  }
}
```

---

## 표준 경로 구조

### 리눅스 FHS (Filesystem Hierarchy Standard)

```
/usr/local/
├── bin/           # 실행 파일 (자동으로 PATH에 포함)
├── lib/           # 공유 라이브러리
├── include/       # 헤더 파일
├── share/         # 아키텍처 독립적 데이터
└── etc/           # 설정 파일
```

### 장점

1. **표준 준수**
   - FHS (Filesystem Hierarchy Standard) 준수
   - 대부분의 리눅스 배포판에서 표준으로 사용

2. **PATH 자동 포함**
   - `/usr/local/bin`은 시스템 기본 PATH에 포함
   - 별도 PATH 설정 불필요

3. **라이브러리 자동 인식**
   - `/usr/local/lib`은 `ldconfig`로 자동 인식
   - `LD_LIBRARY_PATH` 최소화 가능

4. **패키지 관리 용이**
   - CMake, Make 등 빌드 도구의 기본 설치 경로
   - 의존성 관리 단순화

5. **충돌 최소화**
   - 애플리케이션별 전용 경로 불필요
   - 시스템 전역 라이브러리와의 충돌 방지

---

## 환경 변수 비교

### Before (변경 전)

```bash
PATH="/usr/local/xaiva_media/bin:/usr/local/bin:/usr/bin:/bin"
LD_LIBRARY_PATH="/usr/local/xaiva_media/lib:/usr/local/cuda/lib64:/usr/local/cuda/extras/CUPTI/lib64:/usr/local/cuda/include"
```

**문제점**:
- ❌ 전용 경로 관리 복잡
- ❌ 경로 누락 시 실행/링크 실패
- ❌ 다른 애플리케이션과의 경로 충돌 가능
- ❌ `/usr/local/cuda/include`는 LD_LIBRARY_PATH에 불필요

### After (변경 후)

```bash
PATH="/usr/local/bin:/usr/bin:/bin"  # 시스템 기본값 (변경 불필요)
LD_LIBRARY_PATH="/usr/local/lib:/usr/local/cuda/lib64:/usr/local/cuda/extras/CUPTI/lib64"
```

**장점**:
- ✅ 표준 경로만 사용
- ✅ 간결하고 명확
- ✅ 시스템 기본 PATH 활용
- ✅ 필요한 라이브러리 경로만 포함

---

## 빌드 및 설치 가이드

### Xaiva Media 빌드 시 주의사항

#### CMake 설정

```bash
# 올바른 방법: 표준 경로 사용
cmake -DCMAKE_INSTALL_PREFIX=/usr/local ..

# 잘못된 방법: 전용 경로 사용
# cmake -DCMAKE_INSTALL_PREFIX=/usr/local/xaiva_media ..
```

#### 설치 후 라이브러리 캐시 업데이트

```bash
make install
ldconfig  # 필수: 라이브러리 캐시 업데이트
```

`ldconfig`를 실행하지 않으면:
- 공유 라이브러리가 시스템에 인식되지 않음
- 런타임 링크 에러 발생 가능

### 수동 설치 예시

```bash
# 1. 빌드
cd /tmp/xaiva-media
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=/usr/local ..
make -j$(nproc)

# 2. 설치
sudo make install

# 3. 라이브러리 캐시 업데이트 (중요!)
sudo ldconfig

# 4. 확인
which xaiva-app           # /usr/local/bin/xaiva-app 확인
ldconfig -p | grep xaiva  # 라이브러리 등록 확인
```

---

## 런타임 확인

### 실행 파일 찾기

```bash
# 자동으로 찾아짐 (PATH에 /usr/local/bin 포함)
xaiva-app --version

# 또는
which xaiva-app
# 출력: /usr/local/bin/xaiva-app
```

### 라이브러리 링크 확인

```bash
# 동적 라이브러리 의존성 확인
ldd /usr/local/bin/xaiva-app

# 출력 예시:
#   libxaiva_core.so => /usr/local/lib/libxaiva_core.so (0x00007f...)
#   libcudart.so.11.0 => /usr/local/cuda/lib64/libcudart.so.11.0 (0x00007f...)
#   libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007f...)
```

모든 라이브러리가 `=> /usr/local/lib/...` 또는 시스템 경로에서 찾아지면 성공입니다.

### 환경 변수 확인

```bash
# 컨테이너 내에서
echo $PATH
# 출력: /usr/local/bin:/usr/bin:/bin:...

echo $LD_LIBRARY_PATH
# 출력: /usr/local/lib:/usr/local/cuda/lib64:/usr/local/cuda/extras/CUPTI/lib64
```

---

## 마이그레이션 체크리스트

### Dockerfile 작성 시

- [ ] `CMAKE_INSTALL_PREFIX=/usr/local` 사용
- [ ] 설치 후 `ldconfig` 실행
- [ ] `PATH`에 `/usr/local/xaiva_media/bin` 제거
- [ ] `LD_LIBRARY_PATH`에 `/usr/local/xaiva_media/lib` 제거
- [ ] `/usr/local/lib` 포함
- [ ] CUDA 경로만 명시적으로 추가

### 프리셋 JSON 작성 시

- [ ] `environment.LD_LIBRARY_PATH`에서 xaiva_media 경로 제거
- [ ] `/usr/local/lib` 포함
- [ ] CUDA 경로 포함
- [ ] 불필요한 include 경로 제거

### 빌드 후 테스트

- [ ] 실행 파일이 `/usr/local/bin`에 설치됨
- [ ] `which <app-name>`으로 찾아짐
- [ ] `ldd <app-path>`로 모든 라이브러리 링크 확인
- [ ] 애플리케이션 정상 실행
- [ ] GPU 접근 확인 (CUDA 라이브러리)

---

## 문제 해결

### 문제 1: 실행 파일을 찾을 수 없음

```bash
bash: xaiva-app: command not found
```

**원인**: PATH에 `/usr/local/bin`이 없음

**해결**:
```bash
export PATH="/usr/local/bin:$PATH"
# 또는
/usr/local/bin/xaiva-app  # 절대 경로 사용
```

### 문제 2: 공유 라이브러리를 찾을 수 없음

```bash
error while loading shared libraries: libxaiva_core.so: cannot open shared object file
```

**원인 1**: `ldconfig`를 실행하지 않음

**해결**:
```bash
sudo ldconfig
```

**원인 2**: `LD_LIBRARY_PATH`에 `/usr/local/lib`가 없음

**해결**:
```bash
export LD_LIBRARY_PATH="/usr/local/lib:$LD_LIBRARY_PATH"
```

### 문제 3: CUDA 라이브러리를 찾을 수 없음

```bash
error while loading shared libraries: libcudart.so.11.0: cannot open shared object file
```

**해결**:
```bash
export LD_LIBRARY_PATH="/usr/local/cuda/lib64:$LD_LIBRARY_PATH"
```

---

## 추가 권장사항

### 1. pkg-config 설정 (선택 사항)

라이브러리를 더 쉽게 찾을 수 있도록 `.pc` 파일 생성:

```bash
# /usr/local/lib/pkgconfig/xaiva.pc
cat > /usr/local/lib/pkgconfig/xaiva.pc << EOF
prefix=/usr/local
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
includedir=\${prefix}/include

Name: Xaiva Media
Description: Xaiva Media Library
Version: 1.0.0
Libs: -L\${libdir} -lxaiva_core
Cflags: -I\${includedir}
EOF

# 사용
export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH"
pkg-config --cflags --libs xaiva
```

### 2. 심볼릭 링크 (필요 시)

기존 경로 호환성이 필요한 경우:

```bash
# 임시 호환성 유지 (권장하지 않음)
ln -s /usr/local /usr/local/xaiva_media
```

### 3. 환경 설정 파일

프로파일에 환경 변수 추가:

```bash
# /etc/profile.d/xaiva.sh
export LD_LIBRARY_PATH="/usr/local/lib:/usr/local/cuda/lib64:$LD_LIBRARY_PATH"
```

---

## 결론

표준 경로 사용의 이점:
- ✅ **단순성**: 경로 관리 최소화
- ✅ **호환성**: 모든 리눅스 시스템에서 동일
- ✅ **유지보수성**: 표준을 따라 문제 해결 용이
- ✅ **이식성**: 다른 환경으로 쉽게 이식
- ✅ **안정성**: 라이브러리 충돌 최소화

**권장**: 새로운 프로젝트는 항상 표준 경로(`/usr/local`)를 사용하세요.

---

**작성일**: 2025-11-20  
**적용 버전**: Phase 2-4 이후

