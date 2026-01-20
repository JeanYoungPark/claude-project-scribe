#!/bin/bash

# Unsplash API Helper Script
# 프로젝트 키워드 기반으로 커버 이미지 검색

# 설정 파일에서 API 키 읽기
CONFIG_FILE="$(dirname "$0")/../.mcp.json"
UNSPLASH_ACCESS_KEY=$(cat "$CONFIG_FILE" | jq -r '.unsplashApiKey // empty')

if [ -z "$UNSPLASH_ACCESS_KEY" ]; then
    echo "Error: Unsplash API key not found in .mcp.json" >&2
    echo "Please add 'unsplashApiKey' field to .mcp.json" >&2
    echo "Get your API key from: https://unsplash.com/developers" >&2
    exit 1
fi

# Unsplash API 베이스 URL
BASE_URL="https://api.unsplash.com"

# 키워드로 이미지 검색
# Usage: search_images <keywords> [orientation] [per_page]
search_images() {
    local query="$1"
    local orientation="${2:-landscape}"  # landscape, portrait, squarish
    local per_page="${3:-10}"

    curl -s "$BASE_URL/search/photos" \
        -H "Authorization: Client-ID $UNSPLASH_ACCESS_KEY" \
        -G \
        --data-urlencode "query=$query" \
        --data-urlencode "orientation=$orientation" \
        --data-urlencode "per_page=$per_page" \
        --data-urlencode "content_filter=high"
}

# 랜덤 이미지 가져오기
# Usage: get_random <query> [orientation]
get_random() {
    local query="$1"
    local orientation="${2:-landscape}"

    curl -s "$BASE_URL/photos/random" \
        -H "Authorization: Client-ID $UNSPLASH_ACCESS_KEY" \
        -G \
        --data-urlencode "query=$query" \
        --data-urlencode "orientation=$orientation" \
        --data-urlencode "content_filter=high"
}

# 검색 결과에서 첫 번째 이미지 URL 추출
# Usage: get_first_image_url <keywords>
get_first_image_url() {
    local query="$1"
    local orientation="${2:-landscape}"

    local result=$(search_images "$query" "$orientation" 1)
    echo "$result" | jq -r '.results[0].urls.regular // empty'
}

# 랜덤 이미지 URL 추출
# Usage: get_random_image_url <keywords>
get_random_image_url() {
    local query="$1"
    local orientation="${2:-landscape}"

    local result=$(get_random "$query" "$orientation")
    echo "$result" | jq -r '.urls.regular // empty'
}

# 프로젝트 태그 기반으로 최적의 커버 이미지 URL 반환
# Usage: get_cover_for_project <tag1,tag2,tag3>
get_cover_for_project() {
    local tags="$1"
    local orientation="${2:-landscape}"

    # 쉼표로 구분된 태그를 공백으로 변환
    local query=$(echo "$tags" | sed 's/,/ /g')

    # 첫 번째 시도: 모든 태그로 검색
    local url=$(get_first_image_url "$query" "$orientation")

    if [ -n "$url" ]; then
        echo "$url"
        return 0
    fi

    # 두 번째 시도: 첫 2개 태그만
    local first_two=$(echo "$tags" | cut -d',' -f1-2 | sed 's/,/ /g')
    url=$(get_first_image_url "$first_two" "$orientation")

    if [ -n "$url" ]; then
        echo "$url"
        return 0
    fi

    # 세 번째 시도: 첫 번째 태그만
    local first_tag=$(echo "$tags" | cut -d',' -f1)
    url=$(get_random_image_url "$first_tag" "$orientation")

    if [ -n "$url" ]; then
        echo "$url"
        return 0
    fi

    echo "Error: Could not find image for query: $tags" >&2
    return 1
}

# 메인 실행
case "$1" in
    search)
        search_images "$2" "$3" "$4"
        ;;
    random)
        get_random "$2" "$3"
        ;;
    first-url)
        get_first_image_url "$2" "$3"
        ;;
    random-url)
        get_random_image_url "$2" "$3"
        ;;
    cover)
        get_cover_for_project "$2" "$3"
        ;;
    *)
        echo "Unsplash API Helper"
        echo ""
        echo "Usage:"
        echo "  $0 search <keywords> [orientation] [per_page]"
        echo "  $0 random <keywords> [orientation]"
        echo "  $0 first-url <keywords> [orientation]"
        echo "  $0 random-url <keywords> [orientation]"
        echo "  $0 cover <tag1,tag2,tag3> [orientation]"
        echo ""
        echo "Orientation: landscape (default), portrait, squarish"
        echo ""
        echo "Examples:"
        echo "  $0 search 'react typescript' landscape 5"
        echo "  $0 random 'education game' landscape"
        echo "  $0 first-url 'web development'"
        echo "  $0 cover 'react,typescript,game' landscape"
        ;;
esac
