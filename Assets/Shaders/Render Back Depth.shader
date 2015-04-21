Shader "Hidden/Ray Marching/Render Back Depth" {

	CGINCLUDE
		#pragma exclude_renderers xbox360
		#include "UnityCG.cginc"

		struct v2f {
			float4 pos : POSITION;
			float4 spos : TEXCOORD0;
		};

		v2f vert(appdata_base v) 
		{
			v2f o;
			o.pos = o.spos =mul(UNITY_MATRIX_MVP, v.vertex);
			return o;
		}

		float frag(v2f i) : SV_Target
		{ 
			return i.spos.z / i.spos.w;
		}
	ENDCG

	Subshader 
	{
		Tags {"RenderType"="Volume"}
		Fog { Mode Off }

		Pass
		{
			Cull Front
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			ENDCG
		}
	}
	Fallback Off
}
