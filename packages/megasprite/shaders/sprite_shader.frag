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

    float pixelU = cellUV.x + float(i) * 2.0;
    float u1 = (pixelU + 0.5) / uPositionDataSize.x;
    float u2 = (pixelU + 1.5) / uPositionDataSize.x;
    float v = (cellUV.y + 0.5) / uPositionDataSize.y;

    vec4 aabbData = texture(uPositionData, vec2(u1, v));
    vec4 srcData = texture(uPositionData, vec2(u2, v));

    vec2 aabbMin = (aabbData.rg * 255.0) - kSignedByteOffset;
    vec2 aabbMax = (aabbData.ba * 255.0) - kSignedByteOffset;

    vec2 srcUV = srcData.rg;
    vec2 srcSize = srcData.ba;

    if (pixelInCell.x >= aabbMin.x && pixelInCell.x < aabbMax.x + 1.0 &&
        pixelInCell.y >= aabbMin.y && pixelInCell.y < aabbMax.y + 1.0) {

      vec2 localPos = pixelInCell - aabbMin;
      vec2 spriteSize = aabbMax - aabbMin;
      vec2 spriteUV = localPos / spriteSize;

      vec2 texCoord = srcUV + spriteUV * srcSize;

      vec4 texColor = texture(uAtlasTexture, texCoord);
      fragColor = mix(fragColor, texColor, texColor.a);
    }
  }
}
