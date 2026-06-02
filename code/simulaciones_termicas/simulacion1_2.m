limsup = 24;
liminf = 22;
x = linspace(0, 700, 100);
y1 = ones(size(x))*limsup;
y2 = ones(size(x))*liminf;

hold on

yyaxis left
plot(out.salida)
plot(x,y1,'r--')
plot(x,y2,'r--')
ylabel("Temperatura [C°]")
yyaxis right
plot(out.entrada)
ylabel("Tiempo [s]")
ylabel("Voltaje [V]")
title("Controlador histeresis - rango operacion 22°C y 24°C")
legend("Señal de temperatura", 'limite superior', 'limite inferior',"Senal de voltaje")
grind mirror
hold off