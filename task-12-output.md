# Projeto Angular Hello World

Vou criar um projeto Angular "Hello World" completo. Seguem os passos e arquivos necessários.

## 1. Criação do Projeto

```bash
# Instalar o Angular CLI globalmente (caso não tenha)
npm install -g @angular/cli

# Criar novo projeto
ng new hello-world-app --routing=false --style=css --skip-tests=false

# Entrar no diretório
cd hello-world-app

# Servir a aplicação
ng serve --open
```

## 2. Estrutura de Arquivos Principais

```
hello-world-app/
├── src/
│   ├── app/
│   │   ├── app.component.ts
│   │   ├── app.component.html
│   │   ├── app.component.css
│   │   └── app.config.ts
│   ├── index.html
│   ├── main.ts
│   └── styles.css
├── angular.json
└── package.json
```

## 3. Código dos Arquivos

### `src/app/app.component.ts`

```typescript
import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.css']
})
export class AppComponent {
  title = 'Hello World';
  message = 'Bem-vindo ao seu primeiro projeto Angular!';

  // Exemplo de data binding dinâmico
  getCurrentYear(): number {
    return new Date().getFullYear();
  }
}
```

### `src/app/app.component.html`

```html
<div class="container">
  <header class="header">
    <h1>{{ title }} 🚀</h1>
  </header>

  <main class="content">
    <p class="message">{{ message }}</p>
    <p class="info">Projeto criado com Angular Standalone Components.</p>
  </main>

  <footer class="footer">
    <p>&copy; {{ getCurrentYear() }} - Projeto Teste</p>
  </footer>
</div>
```

### `src/app/app.component.css`

```css
.container {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  min-height: 100vh;
  font-family: 'Segoe UI', Tahoma, sans-serif;
  background: linear-gradient(135deg, #dd0031 0%, #c3002f 100%);
  color: #ffffff;
  text-align: center;
}

.header h1 {
  font-size: 3rem;
  margin-bottom: 1rem;
}

.content .message {
  font-size: 1.5rem;
  font-weight: 600;
}

.content .info {
  font-size: 1rem;
  opacity: 0.85;
}

.footer {
  position: absolute;
  bottom: 20px;
  font-size: 0.875rem;
  opacity: 0.7;
}
```

### `src/app/app.config.ts`

```typescript
import { ApplicationConfig } from '@angular/core';

export const appConfig: ApplicationConfig = {
  providers: []
};
```

### `src/main.ts`

```typescript
import { bootstrapApplication } from '@angular/platform-browser';
import { appConfig } from './app/app.config';
import { AppComponent } from './app/app.component';

bootstrapApplication(AppComponent, appConfig)
  .catch((err) => console.error(err));
```

### `src/index.html`

```html
<!doctype html>
<html lang="pt-BR">
<head>
  <meta charset="utf-8">
  <title>Hello World App</title>
  <base href="/">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <link rel="icon" type="image/x-icon" href="favicon.ico">
</head>
<body>
  <app-root></app-root>
</body>
</html>
```

## 4. Teste Unitário (`src/app/app.component.spec.ts`)

```typescript
import { TestBed } from '@angular/core/testing';
import { AppComponent } from './app.component';

describe('AppComponent', () => {
  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [AppComponent],
    }).compileComponents();
  });

  it('deve criar o componente', () => {
    const fixture = TestBed.createComponent(AppComponent);
    const app = fixture.componentInstance;
    expect(app).toBeTruthy();
  });

  it(`deve ter o título 'Hello World'`, () => {
    const fixture = TestBed.createComponent(AppComponent);
    const app = fixture.componentInstance;
    expect(app.title).toEqual('Hello World');
  });

  it('deve renderizar o título no template', () => {
    const fixture = TestBed.createComponent(AppComponent);
    fixture.detectChanges();
    const compiled = fixture.nativeElement as HTMLElement;
    expect(compiled.querySelector('h1')?.textContent).toContain('Hello World');
  });
});
```

## 5. Comandos Úteis

```bash
# Desenvolvimento
ng serve                 # Servidor local em http://localhost:4200

# Testes
ng test                  # Executa os testes unitários

# Build de produção
ng build --configuration production
```

---

## ✅ Resultado da Tarefa

| Item | Status |
|------|--------|
| Projeto Angular criado | ✔️ Concluído |
| Componente Hello World | ✔️ Concluído |
| Estilização básica | ✔️ Concluído |
| Testes unitários | ✔️ Concluído |
| Arquitetura Standalone | ✔️ Concluído |

**Observações:**
- Foi utilizada a abordagem **Standalone Components** (padrão moderno do Angular 17+), eliminando a necessidade de `NgModule`.
- A aplicação demonstra conceitos fundamentais: **interpolação** (`{{ }}`), **data binding** e **chamada de métodos** no template.
- Ao executar `ng serve --open`, a página abrirá automaticamente exibindo "**Hello World 🚀**".

Precisa que eu adicione **roteamento**, **integração com API** ou **deploy** (ex.: Firebase/Netlify)?