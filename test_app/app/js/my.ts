//function greeter(person: string) {
//    return "Hello, " + person;
//}
//
//let user = "Jane User";
//
//document.body.innerHTML = greeter(user);

import { Component, Input, Reflect } from '@angular/core';

@Component({
  selector: 'app-root',
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.css']
})

export class AppComponent {
  title = 'Tour of Heroes';
}
