
Dette prosjektet er en enkel raytracer utviklet fra bunn av i Unity, med HLSL for shader-programmering. Prosjektet følger innholdet og oppbygningen i boka *Ray Tracing in One Weekend* av Peter Shirley (https://raytracing.github.io/books/RayTracingInOneWeekend.html).
Boken bruker C+ ved utvikling av raytraceren, men denne raytraceren er skrevet i shaderspråket HLSL.
Raytraceren ble byggen under kurset DAT253 på HVL Bergen.



## Hva prosjektet gjør

- Implementerer lysstråler, kamera og objekter i form av kuler.
- Kulene har forskjellige tre forskjellige materialer. Matt, metallisk og glass. Alle tre realisert ved unike måter lysstrålene blir reflektert på.
- Egenskaper som antialiasing er også implementert.

## Skjermbilder av prosjektet
En glasskule, en diffus kule og en børstet metallisk kule
<img width="1214" height="619" alt="Skjermbilde 2025-07-28 205812" src="https://github.com/user-attachments/assets/14da76f6-a151-4542-ac6e-9f86aacbddd7" />

Flyttet kule for å demonstrere refraksjon i glasskule
<img width="1291" height="656" alt="Skjermbilde 2025-07-28 210200" src="https://github.com/user-attachments/assets/e302f475-6a10-4f5f-a822-3712a44e56c0" />


