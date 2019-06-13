//
//  TAYLOR SERIES EXPANSION IN MIPS ASSEMBLY
//  by Stefan Goldschmidt and Oliver Rudzinski
//
//  DHBW Stuttgart, Computer Architecture, TINF17A
//  Prof. Dr.-Ing. Alfred Strey
//

#include <stdio.h>

float taylor_exp(float x);
float taylor_ln(float x);
float taylor_ln0(float x);

int main(int argc, const char * argv[]) {

  printf("x\te(x)\tln(x) \n");
  
  for (float x = -8.1; x <= 8.1; x += 0.1) {
    printf("%f\t%f\t%f \n", x, taylor_exp(x), taylor_ln(x));
  }
  
  return 0;
}

float taylor_exp(float x) {
  float nom = 1.0;
  float den = 1.0;
  
  float sum = nom / den;
  
  for (int i = 1; i <= 30; i++) {
    nom = nom * x;
    den = den * i;
    
    sum = sum + (nom / den);
  }
  
  return sum;
  
}

float taylor_ln(float x) {
  float nom = x - 1.0;
  float den = 1.0;
  
  int sign = 1;
  
  float sum = sign * (nom / den);
  
  for (int i = 1; i <= 250; i++) {
    nom = nom * (x - 1);
    den = den + 1;
    sign = sign * (-1);
    
    sum = sum + (sign * (nom / den));
  }
  
  return sum;
}

float taylor_ln0(float x) {
  float sum;
  float a = x;
  float b = 0;
  
  while(a > 2) {
    a = a/2;
    b++;
  }
  
  sum = taylor_ln(a) + b * taylor_ln(2.0);
    
  return sum;
}
