Shader "Hidden/Ray Marching/Ray Marching" 
{
    
    CGINCLUDE
    
    #include "UnityCG.cginc"
    #pragma target 3.0
    #pragma profileoption MaxLocalParams=1024 
    #pragma profileoption NumInstructionSlots=4096
    #pragma profileoption NumMathInstructionSlots=4096
    
    struct v2f {
        float4 pos : POSITION;
        float4 spos : TEXCOORD0;
    };
    
    sampler2D _MainTex;
    float4 _MainTex_TexelSize;
    
    sampler2D _NoiseTex;
    sampler2D _FrontTex;
    sampler2D _BackTex;
    sampler2D _CameraDepthTexture;
    
    float4 _LightDir;
    float4 _LightPos;
    float _Dimensions;
    float4x4 InvMVP;


    v2f vert( appdata_img v ) 
    {
        v2f o;
        o.pos = o.spos = mul(UNITY_MATRIX_MVP, v.vertex);
        return o;
    }
    
    #define STEP_CNT 64
    #define DIMENSIONS 8.0
    
    float2 toTexPos(float3 pos)
    {
        pos += 0.5;
        float2 tex =  float2(
            pos.x / DIMENSIONS + floor(frac(pos.z * DIMENSIONS) * DIMENSIONS) / DIMENSIONS,
            1.0 - (pos.y / DIMENSIONS + floor(pos.z * DIMENSIONS) / DIMENSIONS));
        return tex;

//		return float2(
//			pos.x / _Dimensions + (floor(pos.z * _Dimensions) / _Dimensions),
//			pos.y);		
    }
    
    half4 raymarch(v2f i, float offset) 
    {
        float2 spos = i.spos.xy / i.spos.w;
        float2 tc = spos * 0.5 + 0.5;
#if UNITY_UV_STARTS_AT_TOP
        spos.y *= -1.0;
        tc.y = 1.0 - tc.y;
#endif

        float frontDepth = tex2D(_FrontTex, tc).x;
        if(frontDepth==1.0) return 0.0;
        float backDepth = tex2D(_BackTex, tc).x;
        float sceneDepth = tex2D(_CameraDepthTexture, tc).x;

        float4 frontPos4 = mul(InvMVP, float4(spos, frontDepth, 1.0));
        float4 backPos4 = mul(InvMVP, float4(spos, backDepth, 1.0));
        float3 frontPos = frontPos4.xyz / frontPos4.w;
        float3 backPos = backPos4.xyz / backPos4.w;

        float stepDepth = (backDepth - frontDepth) / STEP_CNT;
        float3 stepDist = (backPos - frontPos) / STEP_CNT;
        float3 pos = frontPos;
        float4 dst = 0;

        for(int k = 0; k < STEP_CNT; k++)
        {
            if(frontDepth + stepDepth*k > sceneDepth) {
                break;
            }
            float4 src = tex2D(_MainTex, toTexPos(pos));

            //Front to back blending
            //dst.rgb = dst.rgb + (1 - dst.a) * src.a * src.rgb;
            //dst.a   = dst.a   + (1 - dst.a) * src.a;     

            src.rgb *= src.a;

            dst = (1.0f - dst.a) * src + dst; 
            pos += stepDist;
        }

        return dst;
    }

    ENDCG
    
Subshader {
    ZTest Always Cull Off ZWrite Off
    Fog { Mode off }
        
    Pass 
    {
        CGPROGRAM
        #pragma vertex vert
        #pragma fragment frag
        half4 frag(v2f i) : COLOR { return raymarch(i, 0); }	
        ENDCG
    }					
}

Fallback off
    
} // shader