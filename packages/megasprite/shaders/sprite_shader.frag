uniform vec2 uCanvasSize;
uniform vec2 uGridSize;
uniform vec2 uAtlasSize;
uniform vec2 uPositionDataSize;
uniform float uCellSize;
uniform sampler2D uAtlasTexture;
uniform sampler2D uPositionData;
uniform sampler2D uCellCounts;

out vec4 fragColor;

const int kMaxSpritesPerCell = 255;
const float kSignedByteOffset = 128.0;
const float kRotationBitMask = 32.0;
const float kFlipXBitMask = 64.0;
const float kFlipYBitMask = 128.0;
const float kEffectBitShift = 5.0;
const float kDimensionMask = 31.0;

void main() {
  vec2 pixelPos = gl_FragCoord.xy;
  fragColor = vec4(0.0);

  vec2 cellCoord = floor(pixelPos / uCellSize);
  float cellIndex = cellCoord.y * uGridSize.x + cellCoord.x;

  vec2 pixelInCell = mod(pixelPos, uCellSize);

  vec2 cellCountUV = (cellCoord + 0.5) / uGridSize;
  float cellSpriteCount = texture(uCellCounts, cellCountUV).r * 255.0;

  for (int i = 0; i < kMaxSpritesPerCell; i++) {
    if (float(i) >= cellSpriteCount) break;

    if (fragColor.a >= 0.99) break;

    float pixelU = float(i) * 3.0;
    float pixelV = cellIndex;

    float u1 = (pixelU + 0.5) / uPositionDataSize.x;
    float u2 = (pixelU + 1.5) / uPositionDataSize.x;
    float u3 = (pixelU + 2.5) / uPositionDataSize.x;
    float v = (pixelV + 0.5) / uPositionDataSize.y;

    vec4 posData = texture(uPositionData, vec2(u1, v));
    vec4 atlasPosData = texture(uPositionData, vec2(u2, v));
    vec4 atlasSizeData = texture(uPositionData, vec2(u3, v));

    vec2 spritePos = (posData.rg * 255.0) - kSignedByteOffset;
    vec2 spriteSize = posData.ba * 255.0;

    vec2 spriteMin = spritePos;
    vec2 spriteMax = spritePos + spriteSize;

    vec2 atlasPos = vec2(
      atlasPosData.r * 255.0 + atlasPosData.g * 255.0 * 256.0,
      atlasPosData.b * 255.0 + atlasPosData.a * 255.0 * 256.0
    );

    float widthHighByte = floor(atlasSizeData.g * 255.0 + 0.5);
    float heightHighByte = floor(atlasSizeData.a * 255.0 + 0.5);

    bool rotated = mod(widthHighByte, kFlipXBitMask) >= kRotationBitMask;
    bool flipX = mod(widthHighByte, kFlipYBitMask) >= kFlipXBitMask;
    bool flipY = widthHighByte >= kFlipYBitMask;
    float effect = floor(heightHighByte / kRotationBitMask);

    float widthLowByte = floor(atlasSizeData.r * 255.0 + 0.5);
    float heightLowByte = floor(atlasSizeData.b * 255.0 + 0.5);

    vec2 atlasSize = vec2(
      widthLowByte + mod(widthHighByte, kRotationBitMask) * 256.0,
      heightLowByte + mod(heightHighByte, kRotationBitMask) * 256.0
    );

    vec2 atlasMin = atlasPos;
    vec2 atlasMax = atlasPos + atlasSize - vec2(1.0);

    vec2 cellMin = vec2(0.0);
    vec2 cellMax = vec2(uCellSize);

    vec2 aabbMin = max(spriteMin, cellMin);
    vec2 aabbMax = min(spriteMax, cellMax);

    if (pixelInCell.x >= aabbMin.x && pixelInCell.x < aabbMax.x &&
        pixelInCell.y >= aabbMin.y && pixelInCell.y < aabbMax.y) {

      vec2 localPos = pixelInCell - spriteMin;

      vec2 spriteUV = vec2(0.5);
      if (spriteSize.x > 0.0) spriteUV.x = localPos.x / spriteSize.x;
      if (spriteSize.y > 0.0) spriteUV.y = localPos.y / spriteSize.y;

      if (flipX) spriteUV.x = 1.0 - spriteUV.x;
      if (flipY) spriteUV.y = 1.0 - spriteUV.y;

      vec2 atlasUV = rotated ? vec2(1.0 - spriteUV.y, spriteUV.x) : spriteUV;
      vec2 atlasPixel = atlasMin + atlasUV * atlasSize;
      vec2 texCoord = atlasPixel / uAtlasSize;

      vec4 texColor = texture(uAtlasTexture, texCoord);
      fragColor = mix(fragColor, texColor, texColor.a);
    }
  }
}
