Shader "Unlit/Glass"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}

		_BaseColour("Base Colour", Color) = (1, 1, 1, 1)
		_EdgeColour("Edge Colour", Color) = (1, 1, 1, 1)
		_ColourExponent("Colour Exponent", Float) = 1

		_BaseReflectiveness("Base Reflectiveness", Float) = 0.01
		_EdgeReflectiveness("Edge Reflectiveness", Float) = 0.5
		_ReflectivenessExponent("Reflectiveness Exponent", Float) = 2
    }
    SubShader
    {
		Tags {"Queue" = "Transparent" "RenderType" = "Transparent"}
        LOD 100

		ZWrite Off

        Pass
        {
			// Multiplicative blend
			Blend DstColor Zero

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;

				float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;

				float3 localPos : TEXCOORD1;
				float3 normalDir : TEXCOORD2;
				float3 viewDir : TEXCOORD3;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

			fixed4 _BaseColour;
			fixed4 _EdgeColour;
			float _ColourExponent;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);

				o.localPos = v.vertex;
				o.viewDir = mul(unity_ObjectToWorld, v.vertex).xyz - _WorldSpaceCameraPos;
				o.normalDir = mul(float4(v.normal, 0.0), unity_WorldToObject).xyz;

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
				float3 normalizedViewDir = normalize(i.viewDir);
				float3 normalizedNormal = normalize(i.normalDir);

				float fresnel = clamp(1 - dot(-normalizedViewDir, normalizedNormal), 0, 1);

				fixed4 col = _BaseColour * lerp(fixed4(1, 1, 1, 1), _EdgeColour, pow(fresnel, _ColourExponent));

                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);

                return col;
            }
            ENDCG
        }

		Pass
		{
			// Regular blend
			//Blend SrcAlpha OneMinusSrcAlpha
			// I think reflections on glass are only additive
			Blend SrcAlpha One

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog

			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;

				float3 normal : NORMAL;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;

				float3 localPos : TEXCOORD1;
				float3 normalDir : TEXCOORD2;
				float3 viewDir : TEXCOORD3;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;

			float _BaseReflectiveness;
			float _EdgeReflectiveness;
			float _ReflectivenessExponent;

			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				UNITY_TRANSFER_FOG(o,o.vertex);

				o.localPos = v.vertex;
				o.viewDir = mul(unity_ObjectToWorld, v.vertex).xyz - _WorldSpaceCameraPos;
				o.normalDir = mul(float4(v.normal, 0.0), unity_WorldToObject).xyz;

				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				float3 normalizedViewDir = normalize(i.viewDir);
				float3 normalizedNormal = normalize(i.normalDir);
				float3 reflectedDir = reflect(normalizedViewDir, normalizedNormal);


				float fresnel = clamp(1 - dot(-normalizedViewDir, normalizedNormal), 0, 1);

				fixed4 col = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, reflectedDir, 0);
				col.a = lerp(_BaseReflectiveness, lerp(_BaseReflectiveness, 1, _EdgeReflectiveness), pow(fresnel, _ReflectivenessExponent));

				// apply fog
				UNITY_APPLY_FOG(i.fogCoord, col);

				return col;
			}
			ENDCG
		}
    }
}
