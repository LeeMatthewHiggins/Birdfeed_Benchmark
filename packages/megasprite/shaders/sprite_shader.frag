uniform vec2 uCanvasSize;
uniform vec2 uGridSize;
uniform vec2 uAtlasSize;
uniform vec2 uPositionDataSize;
uniform float uCellsPerRow;
uniform float uCellDataWidth;
uniform float uCellSize;
uniform sampler2D uAtlasTexture;
uniform sampler2D uPositionData;
uniform sampler2D uCellCounts;

out vec4 fragColor;

const int kMaxSpritesPerCell = 255;
const float kSignedByteOffset = 128.0;

void main() {
  vec2 pixelPos = gl_FragCoord.xy;
  fragColor = vec4(0.0);

  vec2 cellCoord = floor(pixelPos / uCellSize);
  float cellIndex = cellCoord.y * uGridSize.x + cellCoord.x;

  vec2 pixelInCell = mod(pixelPos, uCellSize);

  vec2 cellCountUV = (cellCoord + 0.5) / uGridSize;
  float cellSpriteCount = texture(uCellCounts, cellCountUV).r * 255.0;

  float cellRow = floor(cellIndex / uCellsPerRow);
  float cellCol = mod(cellIndex, uCellsPerRow);
  vec2 cellUV = vec2(cellCol * uCellDataWidth, cellRow);

  for (int i = 0; i < kMaxSpritesPerCell; i++) {
    if (float(i) >= cellSpriteCount) break;

    float pixelU = cellUV.x + float(i) * 3.0;
    float u1 = (pixelU + 0.5) / uPositionDataSize.x;
    float u2 = (pixelU + 1.5) / uPositionDataSize.x;
    float u3 = (pixelU + 2.5) / uPositionDataSize.x;
    float v = (cellUV.y + 0.5) / uPositionDataSize.y;

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
    vec2 atlasSize = vec2(
      atlasSizeData.r * 255.0 + atlasSizeData.g * 255.0 * 256.0,
      atlasSizeData.b * 255.0 + atlasSizeData.a * 255.0 * 256.0
    );

    vec2 atlasMin = atlasPos;
    vec2 atlasMax = atlasPos + atlasSize - vec2(1.0);

    vec2 cellMin = vec2(0.0);
    vec2 cellMax = vec2(uCellSize);

    vec2 aabbMin = max(spriteMin, cellMin);
    vec2 aabbMax = min(spriteMax, cellMax);

    if (pixelInCell.x >= aabbMin.x && pixelInCell.x < aabbMax.x &&
        pixelInCell.y >= aabbMin.y && pixelInCell.y < aabbMax.y) {

      vec2 clippedOffsetMin = aabbMin - spriteMin;
      vec2 clippedOffsetMax = spriteMax - aabbMax;

      vec2 atlasRange = atlasMax - atlasMin + vec2(1.0);
      vec2 atlasClipMin = vec2(0.0);
      vec2 atlasClipMax = vec2(0.0);

      if (spriteSize.x > 0.0) {
        atlasClipMin.x = (clippedOffsetMin.x / spriteSize.x) * atlasRange.x;
        atlasClipMax.x = (clippedOffsetMax.x / spriteSize.x) * atlasRange.x;
      }
      if (spriteSize.y > 0.0) {
        atlasClipMin.y = (clippedOffsetMin.y / spriteSize.y) * atlasRange.y;
        atlasClipMax.y = (clippedOffsetMax.y / spriteSize.y) * atlasRange.y;
      }

      vec2 clippedAtlasMin = atlasMin + atlasClipMin;
      vec2 clippedAtlasMax = atlasMax + vec2(1.0) - atlasClipMax;

      vec2 localPos = pixelInCell - aabbMin;
      vec2 aabbSize = aabbMax - aabbMin;
      vec2 atlasPixelRange = clippedAtlasMax - clippedAtlasMin;

      vec2 spriteUV = vec2(0.5);
      if (aabbSize.x > 0.0) spriteUV.x = localPos.x / aabbSize.x;
      if (aabbSize.y > 0.0) spriteUV.y = localPos.y / aabbSize.y;

      vec2 atlasPixel = clippedAtlasMin + spriteUV * atlasPixelRange;
      vec2 texCoord = (atlasPixel + vec2(0.5)) / uAtlasSize;

      vec4 texColor = texture(uAtlasTexture, texCoord);
      fragColor = mix(fragColor, texColor, texColor.a);
    }
  }
}
