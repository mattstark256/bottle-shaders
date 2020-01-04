using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ConstantRotate : MonoBehaviour
{
    [SerializeField]
    private Vector3 rotateSpeed;
    
    void Update()
    {
        transform.rotation = Quaternion.Euler(Time.time * rotateSpeed);
    }
}
