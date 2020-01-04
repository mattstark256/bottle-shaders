Shader "Unlit/Bottle Liquid"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}

		_SurfaceHeight("Surface Height", Float) = 0.5
		_SurfaceNormal("Surface Normal", Vector) = (0, 1, 0, 0)

		_RefractiveIndex("Refractive Index", Float) = 1.33
		_RefractionDistance("Refraction Distance", Float) = 3
		// The surface is flat so intense refraction doesn't look so convincing. Hence I use a more subtle effect.
		_RefractionDistanceSurface("Refraction Distance Surface", Float) = 0.1

		_BaseColour("Base Colour", Color) = (1, 0, 0, 1)
		_FogColour("Fog Colour", Color) = (1, 1, 1, 1)
		_FogExponent("Fog Exponent", Float) = 1.5

		_ReflectionAmount("Reflection Amount", Range(0,1)) = 0.5
		_ReflectionExponent("Reflection Exponent", Float) = 3
    }
    SubShader
    {
		Tags { "RenderType" = "Opaque" "Queue" = "Transparent-1" }
        LOD 100

		// Grab the screen behind the object into _BackgroundTexture
		GrabPass
		{
			"_BackgroundTexture"
		}

		// Front faces
        Pass
        {
			Cull Back

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
				float3 worldPos : TEXCOORD2;
				float3 normalDir : TEXCOORD3;
				float3 viewDir : TEXCOORD4;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

			float _SurfaceHeight;
			float4 _SurfaceNormal;

			fixed4 _BaseColour;
			fixed4 _FogColour;
			float _FogExponent;
			float _RefractiveIndex;
			float _RefractionDistance;

			sampler2D _BackgroundTexture;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);

				o.localPos = v.vertex;
				o.worldPos = mul(unity_ObjectToWorld, v.vertex);
				o.viewDir = mul(unity_ObjectToWorld, v.vertex).xyz - _WorldSpaceCameraPos;
				o.normalDir = mul(float4(v.normal, 0.0), unity_WorldToObject).xyz;

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
				clip(_SurfaceHeight - dot(i.localPos, _SurfaceNormal));

				float3 normalizedViewDir = normalize(i.viewDir);
				float3 normalizedNormal = normalize(i.normalDir);

				float3 refractedDir = refract(normalizedViewDir, normalizedNormal, 1.0 / _RefractiveIndex);

				// Project the frag world position out in the direction of the refracted ray then use it to sample the GrabPass texture
				float4 screenPos = ComputeGrabScreenPos(UnityWorldToClipPos(i.worldPos + refractedDir * _RefractionDistance));
				fixed4 refractedCol = tex2D(_BackgroundTexture, screenPos.xy / screenPos.w);

				float fresnel = clamp(1 - dot(-normalizedViewDir, normalizedNormal), 0, 1);

				fixed4 col = refractedCol * _BaseColour * lerp(_FogColour, fixed4(1, 1, 1, 1), pow(fresnel, _FogExponent));

                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }

		// Back faces (liquid surface)
		Pass
		{
			Cull Front

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
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;

				float3 localPos : TEXCOORD1;
				float3 worldPos : TEXCOORD2;
				float3 normalDir : TEXCOORD3;
				float3 viewDir : TEXCOORD4;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;

			float _SurfaceHeight;
			float4 _SurfaceNormal;

			fixed4 _BaseColour;
			fixed4 _FogColour;
			float _FogExponent;
			float _RefractiveIndex;
			float _RefractionDistanceSurface;
			float _ReflectionAmount;
			float _ReflectionExponent;

			sampler2D _BackgroundTexture;

			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				UNITY_TRANSFER_FOG(o,o.vertex);

				o.localPos = v.vertex;
				o.worldPos = mul(unity_ObjectToWorld, v.vertex);
				o.viewDir = mul(unity_ObjectToWorld, v.vertex).xyz - _WorldSpaceCameraPos;
				o.normalDir = mul(_SurfaceNormal, unity_WorldToObject).xyz;

				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				clip(_SurfaceHeight - dot(i.localPos, _SurfaceNormal));

				float3 normalizedViewDir = normalize(i.viewDir);
				float3 normalizedNormal = normalize(i.normalDir);

				float3 reflectedDir = reflect(normalizedViewDir, normalizedNormal);
				float3 refractedDir = refract(normalizedViewDir, normalizedNormal, 1.0 / _RefractiveIndex);

				fixed4 reflectedCol = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, reflectedDir, 0);

				// Project the frag world position out in the direction of the refracted ray then use it to sample the GrabPass texture
				float4 screenPos = ComputeGrabScreenPos(UnityWorldToClipPos(i.worldPos + refractedDir * _RefractionDistanceSurface));
				fixed4 refractedCol = tex2D(_BackgroundTexture, screenPos.xy / screenPos.w);

				float fresnel = clamp(1 - dot(-normalizedViewDir, normalizedNormal), 0, 1);

				fixed4 col = refractedCol * _BaseColour * lerp(_FogColour, fixed4(1, 1, 1, 1), pow(fresnel, _FogExponent));

				col = lerp(col, reflectedCol, pow(fresnel, _ReflectionExponent) * _ReflectionAmount);

				// apply fog
				UNITY_APPLY_FOG(i.fogCoord, col);
				return col;
			}
			ENDCG
		}
    }
}
